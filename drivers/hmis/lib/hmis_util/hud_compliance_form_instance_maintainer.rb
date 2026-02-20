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
      @missing_rules_summary = [] # used in dry run to collect what would be created
    end

    def ensure_all_system_instances_exist!
      # Create required system instances for record forms (Client, Project, Move-in Date, etc)
      ensure_record_form_system_instances!
      # Create required system instances for assessments (Intake, Exit, etc)
      ensure_assessment_system_instances!
      # TODO(#8874): ensure system instances exist for HUD Service form (Currently handled by HmisUtil::ServiceTypes)
    end

    private

    # Ensures all required system instances exist for HUD record forms: default system form roles,
    # move-in date, date of engagement, path status, and current living situation.
    def ensure_record_form_system_instances!
      @missing_rules_summary = [] if @dry_run

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

      # Ensure required rules exist for Current Living Situation
      HudHelper.util.current_living_situation_funder_applicability_requirements.each do |spec|
        create_system_instance!(
          identifier: FORM_IDENTIFIERS[:current_living_situation],
          data_collected_about: :HOH_AND_ADULTS,
          project_type: spec[:project_type],
          funder: spec[:funder],
        )
      end

      print_compliance_summary('Record forms', @missing_rules_summary) if @dry_run && @missing_rules_summary.any?
    end

    # Ensures required system instances exist for HUD assessments: default rule for intake/exit/update/annual,
    # funder-specific rule for post-exit (RHY aftercare).
    def ensure_assessment_system_instances!
      @missing_rules_summary = [] if @dry_run # reset for assessment section

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

      print_compliance_summary('Assessments', @missing_rules_summary) if @dry_run && @missing_rules_summary.any?
    end

    def create_default_system_instance!(identifier:)
      if @dry_run
        exists = Hmis::Form::Instance.defaults.exists?(definition_identifier: identifier)
        @missing_rules_summary << { type: :default, definition_identifier: identifier } unless exists
        return
      end
      instance = Hmis::Form::Instance.defaults.find_or_initialize_by(definition_identifier: identifier)
      instance.assign_attributes(active: true, system: true)
      instance.save! if instance.changed?
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
      if @dry_run
        @missing_rules_summary << { type: :rule, **attrs } unless Hmis::Form::Instance.active.exists?(attrs)
        return
      end

      instance = Hmis::Form::Instance.find_or_initialize_by(attrs)
      instance.assign_attributes(active: true, system: true)
      instance.save! if instance.changed?
    end

    def print_compliance_summary(section_label, entries)
      default_count = entries.count { |e| e[:type] == :default }
      rule_count = entries.count { |e| e[:type] == :rule }
      by_identifier = entries.select { |e| e[:type] == :rule }.group_by { |e| e[:definition_identifier] }
      lines = [
        "HUD Form Compliance (dry run) — #{section_label} — new instances that would be created:",
        "  Default (all projects): #{default_count}",
        "  Funder/project-type rules: #{rule_count}",
      ]
      by_identifier.each do |identifier, items|
        lines << "    #{identifier}: #{items.size} rule(s)"
      end
      Rails.logger.info lines.join("\n")
      puts lines.join("\n")
    end
  end
end
