# frozen_string_literal: true

module HopwaCaper
  class DrilldownPresenter
    Field = Struct.new(:name, :label, :transform, :not_collected, keyword_init: true)

    def initialize(records, report, user, format: :html)
      @records = records
      @report = report
      @user = user
      @format = format
      @services_by_client = {}
      @field_map = build_field_map
      preload_services if @records.first.is_a?(HopwaCaper::Enrollment)
    end

    def headers
      @field_map.values.map { |f| [f.name, f.label || f.name.humanize] }.to_h
    end

    def display_value(record, field_name)
      field = @field_map[field_name.to_s]
      return record.send(field_name).humanize if field.nil? # Fallback for unexpected fields

      value = if field.name == 'services_summary' && record.is_a?(HopwaCaper::Enrollment)
        services_summary(record)
      elsif record.respond_to?(field.name)
        record.send(field.name)
      end

      value = record[field.name] if value.nil? && record.respond_to?(:[]) && record.class.column_names.include?(field.name.to_s)

      pii_policy = pii_policy_for(record)

      if value.is_a?(Array)
        items = value.map { |v| transform_value(field, v, record, pii_policy) }
        return items.join("\n") unless html?

        return helpers.content_tag(:ul, class: 'list-unstyled mb-0') do
          items.map { |v| helpers.content_tag(:li, v) }.join.html_safe
        end
      end

      if value.in?([true, false])
        return Reports::ModelApplicationHelper.new.yes_no(value, include_content_tag: html?)
      end

      transform_value(field, value, record, pii_policy)
    end

    private

    def enrollment_fields
      @enrollment_fields ||= [
        Field.new(name: 'personal_id', label: 'HMIS Personal ID'),
        Field.new(name: 'hmis_enrollment_id', label: 'HMIS Enrollment ID'),
        Field.new(name: 'first_name', transform: ->(v, poly) { GrdaWarehouse::PiiProvider.viewable_name(v, policy: poly) }),
        Field.new(name: 'last_name', transform: ->(v, poly) { GrdaWarehouse::PiiProvider.viewable_name(v, policy: poly) }),
        Field.new(name: 'destination_client_id', label: 'Warehouse Client ID'),
        Field.new(name: 'age'),
        Field.new(name: 'dob', label: 'Date of Birth', transform: ->(v, poly) { GrdaWarehouse::PiiProvider.viewable_dob(v, policy: poly) }),
        Field.new(name: 'dob_quality', label: 'Date of Birth Quality', transform: ->(v, poly) { hud_helper.dob_data_quality(v) }, not_collected: true),
        Field.new(name: 'races', transform: ->(v, poly) {
          field_name = hud_helper.race_id_to_field_name[v]
          hud_helper.races[field_name.to_s]
        }),
        Field.new(name: 'sex', transform: ->(v, poly) { hud_helper.sex(v) }, not_collected: true),
        Field.new(name: 'veteran'),
        Field.new(name: 'entry_date'),
        Field.new(name: 'exit_date'),
        Field.new(name: 'relationship_to_hoh', label: 'Relationship to HoH', transform: ->(v, poly) { hud_helper.relationship_to_hoh(v) }),
        Field.new(name: 'project_funders', label: 'Project Funder(s)', transform: ->(v, poly) { hud_helper.funding_source(v) }),
        Field.new(name: 'project_type', transform: ->(v, poly) { hud_helper.project_types[v&.to_i] }),
        Field.new(name: 'income_benefit_source_types'),
        Field.new(name: 'medical_insurance_types'),
        Field.new(name: 'household_income_benefit_source_types'),
        Field.new(name: 'household_medical_insurance_types'),
        Field.new(name: 'hiv_positive', label: 'HIV positive'),
        Field.new(name: 'hopwa_eligible'),
        Field.new(name: 'chronically_homeless'),
        Field.new(name: 'prior_living_situation', transform: ->(v, poly) { hud_helper.living_situation(v) }),
        Field.new(name: 'rental_subsidy_type', transform: ->(v, poly) { hud_helper.rental_subsidy_type(v) }),
        Field.new(name: 'exit_destination', transform: ->(v, poly) { hud_helper.destination(v) }, not_collected: true),
        Field.new(name: 'housing_assessment_at_exit', transform: ->(v, poly) { hud_helper.housing_assessment_at_exit(v) }, not_collected: true),
        Field.new(name: 'subsidy_information', transform: ->(v, poly) { hud_helper.subsidy_information(v) }),
        Field.new(name: 'ever_prescribed_anti_retroviral_therapy'),
        Field.new(name: 'viral_load_suppression'),
        Field.new(name: 'percent_ami', label: 'Percent AMI', transform: ->(v, poly) { hud_helper.percent_ami(v) }, not_collected: true),
        Field.new(name: 'atc_maintained_contact', label: 'ATC: Maintained Contact'),
        Field.new(name: 'atc_housing_plan', label: 'ATC: Housing Plan'),
        Field.new(name: 'atc_primary_health_contact', label: 'ATC: Primary Health Contact'),
        Field.new(name: 'services_summary', label: 'Services (Record Type: Type Provided)'),
      ].index_by(&:name).freeze
    end

    def service_field_overrides
      @service_field_overrides ||= {
        'service_source' => Field.new(name: 'service_source', label: 'Service Source'),
        'destination_client_id' => Field.new(name: 'destination_client_id', label: 'Warehouse Client ID'),
        'personal_id' => Field.new(name: 'personal_id', label: 'HMIS Personal ID'),
        'hmis_enrollment_id' => Field.new(name: 'hmis_enrollment_id', label: 'HMIS Enrollment ID'),
        'service_id' => Field.new(name: 'service_id', label: 'HMIS Service ID'),
        'service_category_name' => Field.new(name: 'service_category_name', label: 'Service Category'),
        'service_type_name' => Field.new(name: 'service_type_name', label: 'Service Type'),
      }.freeze
    end

    def build_field_map
      if @records.first.is_a?(HopwaCaper::Enrollment)
        enrollment_fields
      else
        special = ['personal_id', 'hmis_enrollment_id', 'first_name', 'last_name']
        remove = ['id', 'created_at', 'updated_at', 'report_instance_id', 'enrollment_id', 'report_household_id']
        cols = special + (HopwaCaper::Service.column_names - special - remove)

        cols.map do |name|
          field = service_field_overrides[name] || enrollment_fields[name] || Field.new(name: name)
          [name, field]
        end.to_h
      end
    end

    def transform_value(field, value, record, pii_policy)
      # Treat nil as 99 (Data not collected) for HUD fields that support it
      value = 99 if value.nil? && field.not_collected

      if field.transform.respond_to?(:call)
        field.transform.call(value, pii_policy)
      else
        value
      end
    end

    def pii_policy_for(record)
      @user.reporting_policy_for_project(
        project_id: record.project_id,
        mode: html? ? :browse : :download
      )
    end

    def html?
      @format == :html
    end

    def helpers
      ActionController::Base.helpers
    end

    def hud_helper
      @hud_helper ||= HudHelper.util('2026')
    end

    def services_summary(record)
      services = @services_by_client[record.destination_client_id] || []
      services.map do |s|
        if s.record_type && s.type_provided
          category = hud_helper.record_type(s.record_type)
          type = hud_helper.service_type_provided(s.record_type, s.type_provided)
          "#{category}: #{type}"
        else
          s.service_type_name
        end
      end.compact.uniq.sort
    end

    def preload_services
      client_ids = @records.map(&:destination_client_id).uniq
      @services_by_client = @report.hopwa_caper_services.
        where(destination_client_id: client_ids).
        where(date_provided: @report.start_date..@report.end_date).
        group_by(&:destination_client_id)
    end
  end
end
