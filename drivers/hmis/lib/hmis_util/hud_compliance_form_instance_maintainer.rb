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
      service: 'service',
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

    def initialize(dry_run: false, data_source_id: nil)
      @dry_run = dry_run
      # TODO(#6691) require data source. Currently this class allows it to be missing because this gets run in rails helper before data sources are created.
      @data_source = data_source_id ? GrdaWarehouse::DataSource.hmis.find(data_source_id) : GrdaWarehouse::DataSource.hmis.first
      @created = []  # OpenStruct(type:, definition_identifier:, project_type?, funder?) for reporting
      @updated = []  # same shape: existing instances changed to system/active
      setup_notifier('HUD Form Compliance')
    end

    def ensure_all_system_instances_exist!
      # Create required system instances for record forms (Client, Project, Move-in Date, etc)
      ensure_record_form_system_instances!
      # Create required system instances for assessments (Intake, Exit, etc)
      ensure_assessment_system_instances!

      # Create required system instances for HUD Service form (identifier = 'service')
      if Rails.env.test? && @data_source.blank?
        # Unable to set up service form instances without data source specified
        # TODO(#6691) when data source is guaranteed to be present during form seeding in test, we can remove this.
        Rails.logger.info 'No data source found. Skipping service form system instances in test. FIXME(#6691)'
      else
        ensure_service_form_system_instances!
      end

      # Report changes
      report_changes_if_any
    end

    private

    def definition_scope
      # TODO(#6691): add 'where(data_source: @data_source)'
      Hmis::Form::Definition.published.managed_in_version_control
    end

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

    # Ensures required system instances exist for the HUD Service form
    # Requirements come from HudHelper.util.service_form_funder_applicability_requirements.
    def ensure_service_form_system_instances!
      service_identifier = FORM_IDENTIFIERS[:service]
      raise "form not found: #{service_identifier}" unless definition_scope.where(identifier: service_identifier).exists?

      # Ensure HUD Service Types and Categories exist for the data source
      unless Hmis::Hud::CustomServiceType.hud.where(data_source: @data_source).exists?
        Rails.logger.info "No HUD Service Categories found for DS##{@data_source.id}. Seeding..."
        ::HmisUtil::ServiceTypes.seed_hud_service_types(@data_source.id)
      end

      # { record_type => CustomServiceType } in the data source for HUD Service Types
      service_types = Hmis::Hud::CustomServiceType.hud.where(data_source: @data_source).preload(:custom_service_category).index_by(&:hud_record_type)
      # binding.pry

      # For each record type, create Form Instance(s) per applicability requirement
      HudHelper.util.service_form_funder_applicability_requirements.each do |config|
        record_type = config[:record_type]

        service_type = service_types[record_type]
        service_category = service_type&.custom_service_category
        raise "HUD Service Type not found for record type #{record_type} in DS##{@data_source.id}. Did you run HmisUtil::ServiceTypes.seed_hud_service_types" unless service_type && service_category

        config[:applicability_requirements].each do |requirement|
          create_system_instance!(
            data_collected_about: config[:data_collected_about],
            identifier: service_identifier,
            service_category: service_category,
            project_type: requirement[:project_type],
            funder: requirement[:funder],
          )
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

    def create_system_instance!(identifier:, data_collected_about:, project_type: nil, funder: nil, service_category: nil)
      raise 'must specify project_type and/or funder' if project_type.blank? && funder.blank?
      raise "form not found: #{identifier}" unless definition_scope.where(identifier: identifier).exists?

      attrs = {
        definition_identifier: identifier,
        data_collected_about: data_collected_about,
        project_type: project_type,
        funder: funder,
        entity_type: nil,
        entity_id: nil,
        custom_service_category_id: service_category&.id,
      }
      instance = Hmis::Form::Instance.find_or_initialize_by(attrs)
      was_new = instance.new_record?
      instance.assign_attributes(active: true, system: true)
      return unless instance.changed?

      instance.save! unless @dry_run
      payload = OpenStruct.new(type: :rule, definition_identifier: identifier, project_type: project_type, funder: funder, service_category: service_category&.name)
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
          entry.service_category ? "service_category='#{entry.service_category}'" : nil,
          entry.project_type ? "project_type=#{entry.project_type}" : nil,
          entry.funder ? "funder=#{entry.funder}" : nil,
        ].compact.join(', ')

        "  #{entry.type == :default ? 'default rule' : 'rule'}: #{summary}"
      end.sort
    end
  end
end
