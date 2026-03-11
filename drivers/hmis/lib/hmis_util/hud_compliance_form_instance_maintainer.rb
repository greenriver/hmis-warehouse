###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisUtil
  # Encapsulates HUD compliance rules for form system instances. Creates (or in dry run, reports)
  # the system form instances required for record forms and assessments.
  class HudComplianceFormInstanceMaintainer
    include NotifierConfig

    FORM_IDENTIFIERS = {
      move_in_date: 'move_in_date',
      date_of_engagement: 'date_of_engagement',
      path_status: 'path_status',
      current_living_situation: 'current_living_situation',
      base_intake: 'base-intake',
      base_exit: 'base-exit',
      base_update: 'base-update',
      base_annual: 'base-annual',
      base_post_exit: 'base-post_exit',
    }.freeze

    ASSESSMENT_IDENTIFIERS = [
      FORM_IDENTIFIERS[:base_intake],
      FORM_IDENTIFIERS[:base_exit],
      FORM_IDENTIFIERS[:base_update],
      FORM_IDENTIFIERS[:base_annual],
      FORM_IDENTIFIERS[:base_post_exit],
    ].freeze

    def initialize(dry_run: false)
      @dry_run = dry_run
      @created = []  # OpenStruct(type:, definition_identifier:, project_type?, funder?) for reporting
      @updated = []  # same shape: existing instances changed to system/active
      setup_notifier('HUD Form Compliance')
    end

    def ensure_all_system_instances_exist!
      # Create required system instances for record forms (Client, Project, Move-in Date, etc)
      ensure_record_form_system_instances!
      # Create required system instances for assessments (Intake, Exit, etc)
      ensure_assessment_system_instances!
      # TODO(#8874) ADD: ensure system instances exist for HUD Service form (Currently handled by HmisUtil::ServiceTypes)

      # Report changes
      report_changes_if_any
    end

    private

    # Ensures all required system instances exist for HUD record forms: default system form roles,
    # move-in date, date of engagement, path status, and current living situation.
    def ensure_record_form_system_instances!
      # Ensure form rules exist to enable all System Forms globally
      Hmis::Form::Definition::SYSTEM_FORM_ROLES.each do |role|
        create_default_system_instance!(identifier: role.to_s.downcase)
      end

      # Ensure required rules exist for Move-in Date (Occurrence Point form)
      create_system_instances!(
        identifier: FORM_IDENTIFIERS[:move_in_date],
        data_collected_about: :HOH,
        project_types: HudHelper.util.permanent_housing_project_types,
        funders: HudHelper.util.move_in_date_funders,
      )
      # Ensure required rules exist for Date of Engagement (Occurrence Point form)
      create_system_instances!(
        identifier: FORM_IDENTIFIERS[:date_of_engagement],
        data_collected_about: :HOH_AND_ADULTS,
        project_types: HudHelper.util.doe_project_types,
      )
      # Ensure required rules exist for PATH Status (Occurrence Point form)
      create_system_instances!(
        identifier: FORM_IDENTIFIERS[:path_status],
        data_collected_about: :HOH_AND_ADULTS,
        funders: HudHelper.util.path_funders,
      )

      # Ensure required rules exist for Current Living Situation.
      # Each requirement is a Hash with :project_type and/or :funder
      HudHelper.util.current_living_situation_funder_applicability_requirements.each do |requirement|
        create_system_instance!(
          identifier: FORM_IDENTIFIERS[:current_living_situation],
          data_collected_about: :HOH_AND_ADULTS,
          project_type: requirement[:project_type],
          funder: requirement[:funder],
        )
      end
    end

    # Ensures required system instances exist for HUD assessments: default rule for intake/exit/update/annual,
    # funder-specific rule for post-exit (RHY aftercare).
    def ensure_assessment_system_instances!
      ASSESSMENT_IDENTIFIERS.each do |identifier|
        if identifier == FORM_IDENTIFIERS[:base_post_exit]
          create_system_instances!(
            identifier: identifier,
            data_collected_about: :HOH_AND_ADULTS,
            funders: HudHelper.util.post_exit_aftercare_plans_funders,
          )
        else
          create_default_system_instance!(identifier: identifier)
        end
      end
    end

    def create_default_system_instance!(identifier:)
      instance = Hmis::Form::Instance.defaults.find_or_initialize_by(definition_identifier: identifier)
      was_new = instance.new_record?
      instance.assign_attributes(active: true, system: true)
      return unless instance.changed?

      instance.save! unless @dry_run
      payload = OpenStruct.new(type: :default, definition_identifier: identifier)
      was_new ? @created << payload : @updated << payload
    end

    def create_system_instances!(identifier:, data_collected_about:, project_types: [], funders: [])
      raise 'must specify either project_types or funders' if project_types.empty? && funders.empty?

      project_types.each do |project_type|
        create_system_instance!(identifier: identifier, data_collected_about: data_collected_about, project_type: project_type, funder: nil)
      end
      funders.each do |funder|
        create_system_instance!(identifier: identifier, data_collected_about: data_collected_about, project_type: nil, funder: funder)
      end
    end

    def create_system_instance!(identifier:, data_collected_about:, project_type: nil, funder: nil)
      raise 'must specify project_type and/or funder' if project_type.blank? && funder.blank?
      raise "form not found: #{identifier}" unless Hmis::Form::Definition.published.managed_in_version_control.where(identifier: identifier).exists?

      attrs = {
        definition_identifier: identifier,
        data_collected_about: data_collected_about,
        project_type: project_type,
        funder: funder,
        entity_type: nil,
        entity_id: nil,
      }
      instance = Hmis::Form::Instance.find_or_initialize_by(attrs)
      was_new = instance.new_record?
      instance.assign_attributes(active: true, system: true)
      return unless instance.changed?

      instance.save! unless @dry_run
      payload = OpenStruct.new(type: :rule, definition_identifier: identifier, project_type: project_type, funder: funder)
      was_new ? @created << payload : @updated << payload
    end

    def report_changes_if_any
      message = build_summary_lines.join("\n")
      return if message.blank?

      Rails.logger.info message
      @notifier.ping(message) unless @dry_run
    end

    # One summary format for dry run (would create/update) and real run (created/updated). Entries
    # are OpenStructs with type (:default or :rule), definition_identifier, and for rules project_type, funder.
    def build_summary_lines
      return [] if @created.empty? && @updated.empty?

      title = @dry_run ? 'HUD Form Compliance (dry run) — instances that would be created or updated:' : 'HUD Form Compliance — changes applied:'
      created_label = @dry_run ? "Would create (#{@created.size}):" : "Created (#{@created.size}):"
      updated_label = @dry_run ? "Would update (#{@updated.size}):" : "Updated (#{@updated.size}):"

      lines = [title]
      if @created.any?
        lines << created_label
        lines.concat(format_entries(@created))
      end
      if @updated.any?
        lines << updated_label
        lines.concat(format_entries(@updated))
      end
      lines
    end

    def format_entries(entries)
      entries.map do |entry|
        summary = [
          entry.definition_identifier,
          entry.project_type ? "project_type=#{entry.project_type}" : nil,
          entry.funder ? "funder=#{entry.funder}" : nil,
        ].compact.join(', ')

        "  #{entry.type == :default ? 'default rule' : 'rule'}: #{summary}"
      end.sort
    end
  end
end
