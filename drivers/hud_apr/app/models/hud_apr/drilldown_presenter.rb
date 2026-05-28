# frozen_string_literal: true

module HudApr
  class DrilldownPresenter
    Field = Struct.new(:name, :label, :transform, :not_collected, :pii, keyword_init: true)

    def initialize(records, report, user, question: nil, format: :html)
      @records = records
      @report = report
      @user = user
      @question = question
      @format = format
      @services_by_client = {}
      @field_map = fields_for_question
    end

    def headers
      @field_map.values.map { |f| [f.name, f.label || f.name.humanize] }.to_h
    end

    def display_value(record, field_name)
      field = @field_map.fetch(field_name.to_s)
      value = record.send(field.name)

      pii_policy = pii_policy_for(record)
      if value.is_a?(Array)
        return format_list(value.map { |v| transform_value(field, v, record, pii_policy) })
      elsif value.is_a?(Hash)
        items = value.filter_map { |k, v| "#{k}: #{transform_value(field, v, record, pii_policy)}" unless v.nil? }
        return format_list(items)
      end

      # PII fields must always run through their transform, even for boolean values,
      # so the policy can redact them.
      return transform_value(field, value, record, pii_policy) if field.pii
      return Reports::ModelApplicationHelper.new.yes_no(value, include_content_tag: html?) if value.in?([true, false])

      transform_value(field, value, record, pii_policy)
    end

    private

    def format_list(items)
      return items.join("\n") unless html?

      helpers.content_tag(:ul, class: 'list-unstyled mb-0') do
        helpers.safe_join(items.map { |v| helpers.content_tag(:li, v) })
      end
    end

    def enrollment_fields
      @enrollment_fields ||= [
        # PII / Identity
        Field.new(name: 'personal_id', label: 'HMIS Personal ID'),
        Field.new(name: 'first_name', transform: ->(v, poly) { GrdaWarehouse::PiiProvider.viewable_name(v, policy: poly) }),
        Field.new(name: 'last_name', transform: ->(v, poly) { GrdaWarehouse::PiiProvider.viewable_name(v, policy: poly) }),
        Field.new(name: 'destination_client_id', label: 'Warehouse Client ID'),
        Field.new(name: 'ssn', label: 'SSN', transform: ->(v, poly) { GrdaWarehouse::PiiProvider.viewable_ssn(v, policy: poly) }),
        Field.new(name: 'name_quality', label: 'Name Quality', transform: ->(v, _poly) { hud_helper.name_data_quality(v) }),
        Field.new(name: 'ssn_quality', label: 'SSN Quality', transform: ->(v, _poly) { hud_helper.ssn_data_quality(v) }),

        # Demographics
        Field.new(name: 'age'),
        Field.new(name: 'dob', label: 'DOB', transform: ->(v, poly) { GrdaWarehouse::PiiProvider.viewable_dob(v, policy: poly) }),
        Field.new(name: 'dob_quality', label: 'DOB Quality', transform: ->(v, _poly) { hud_helper.dob_data_quality(v) }, not_collected: true),
        Field.new(name: 'sex', transform: ->(v, _poly) { hud_helper.sex(v) }, not_collected: true),
        Field.new(name: 'race_multi', label: 'Race', transform: ->(v, _poly) {
          next if v.nil?

          field_name = hud_helper.race_id_to_field_name[v.to_i]
          hud_helper.races[field_name.to_s] if field_name
        }),
        Field.new(name: 'veteran_status', transform: ->(v, _poly) { hud_helper.veteran_status(v) }),
        Field.new(name: 'relationship_to_hoh', label: 'Relationship to HoH', transform: ->(v, _poly) { hud_helper.relationship_to_hoh(v) }),
        Field.new(name: 'disabling_condition', transform: ->(v, _poly) { hud_helper.disability_response(v) }),
        Field.new(name: 'indefinite_and_impairs'),
        Field.new(name: 'sexual_orientation', transform: ->(v, _poly) { hud_helper.sexual_orientation(v) }),
        Field.new(name: 'preferred_language', transform: ->(v, _poly) { hud_helper.preferred_language(v) }),

        # Parenting
        Field.new(name: 'parenting_youth'),
        Field.new(name: 'parenting_juvenile'),

        # Dates
        Field.new(name: 'first_date_in_program'),
        Field.new(name: 'last_date_in_program'),
        Field.new(name: 'date_of_engagement'),

        # Enrollment
        Field.new(name: 'enrollment_coc', label: 'Enrollment CoC'),

        # Household
        Field.new(name: 'head_of_household'),
        Field.new(name: 'head_of_household_id'),
        Field.new(name: 'household_id'),
        Field.new(name: 'household_type'),
        Field.new(name: 'household_members'),
        Field.new(name: 'move_in_date', label: 'Move-in Date'),
        Field.new(name: 'hoh_move_in_date', label: 'HoH Move-in Date'),
        Field.new(name: 'time_to_move_in'),
        Field.new(name: 'approximate_time_to_move_in'),

        # Homeless history
        Field.new(name: 'chronically_homeless'),
        Field.new(name: 'chronically_homeless_detail'),
        Field.new(name: 'prior_living_situation', transform: ->(v, _poly) { hud_helper.living_situation(v) }),
        Field.new(name: 'prior_length_of_stay', transform: ->(v, _poly) { hud_helper.residence_prior_length_of_stay(v) }),
        Field.new(name: 'approximate_length_of_stay'),
        Field.new(name: 'came_from_street_last_night'),
        Field.new(name: 'date_homeless'),
        Field.new(name: 'times_homeless', transform: ->(v, _poly) { hud_helper.times_homeless_past_three_years(v) }),
        Field.new(name: 'months_homeless', transform: ->(v, _poly) { hud_helper.months_homeless_past_three_years(v) }),
        Field.new(name: 'date_to_street'),
        Field.new(name: 'date_of_last_bed_night'),

        # Health / Disability
        *health_disability_fields,

        # Domestic violence
        Field.new(name: 'domestic_violence'),
        Field.new(name: 'domestic_violence_occurred', label: 'When DV Occurred', transform: ->(v, _poly) { hud_helper.when_d_v_occurred(v) }),
        Field.new(name: 'currently_fleeing'),

        # Financial
        Field.new(name: 'income_date_at_start'),
        Field.new(name: 'income_from_any_source_at_start'),
        Field.new(name: 'income_from_any_source_at_start_raw'),
        Field.new(name: 'income_sources_at_start'),
        Field.new(name: 'income_date_at_annual_assessment', label: 'Income Date at Annual'),
        Field.new(name: 'annual_assessment_in_window'),
        Field.new(name: 'income_from_any_source_at_annual_assessment', label: 'Income from Any Source at Annual'),
        Field.new(name: 'income_from_any_source_at_annual_assessment_raw'),
        Field.new(name: 'income_sources_at_annual_assessment', label: 'Income Sources at Annual'),
        Field.new(name: 'income_date_at_exit'),
        Field.new(name: 'income_from_any_source_at_exit'),
        Field.new(name: 'income_from_any_source_at_exit_raw'),
        Field.new(name: 'income_sources_at_exit'),
        Field.new(name: 'income_total_at_start'),
        Field.new(name: 'income_total_at_annual_assessment', label: 'Income Total at Annual'),
        Field.new(name: 'income_total_at_exit'),
        Field.new(name: 'non_cash_benefits_from_any_source_at_start', label: 'Non-cash Benefits at Start'),
        Field.new(name: 'non_cash_benefits_from_any_source_at_annual_assessment', label: 'Non-cash Benefits at Annual'),
        Field.new(name: 'non_cash_benefits_from_any_source_at_exit', label: 'Non-cash Benefits at Exit'),

        # Insurance
        Field.new(name: 'insurance_from_any_source_at_start', label: 'Insurance at Start'),
        Field.new(name: 'insurance_from_any_source_at_annual_assessment', label: 'Insurance at Annual'),
        Field.new(name: 'insurance_from_any_source_at_exit', label: 'Insurance at Exit'),

        # Subsidy
        Field.new(name: 'subsidy_information', transform: ->(v, _poly) { hud_helper.subsidy_information(v) }),
        Field.new(name: 'exit_destination_subsidy_type'),

        # Assessment
        Field.new(name: 'annual_assessment_expected'),
        Field.new(name: 'housing_assessment', transform: ->(v, _poly) { hud_helper.housing_assessment_at_exit(v) }, not_collected: true),
        Field.new(name: 'ce_assessment_date', label: 'CE Assessment Date'),
        Field.new(name: 'ce_assessment_type', label: 'CE Assessment Type', transform: ->(v, _poly) { hud_helper.assessment_type(v) }),
        Field.new(name: 'ce_assessment_prioritization_status', label: 'CE Prioritization Status', transform: ->(v, _poly) { hud_helper.prioritization_status(v) }),

        # Housing / Destination
        Field.new(name: 'destination', transform: ->(v, _poly) { hud_helper.destination(v) }, not_collected: true),

        # Project
        Field.new(name: 'project_type', transform: ->(v, _poly) { hud_helper.project_type_brief(v) }),
        Field.new(name: 'project_tracking_method'),

        # Timeliness
        Field.new(name: 'enrollment_created'),
        Field.new(name: 'exit_created'),

        # CE Events
        Field.new(name: 'ce_event_date', label: 'CE Event Date'),
        Field.new(name: 'ce_event_event', label: 'CE Event'),
        Field.new(name: 'ce_event_problem_sol_div_rr_result', label: 'CE Problem/Diversion/RR Result'),
        Field.new(name: 'ce_event_referral_case_manage_after', label: 'CE Referral Case Mgmt After'),
        Field.new(name: 'ce_event_referral_result', label: 'CE Referral Result'),
      ].index_by(&:name).freeze
    end

    def fields_for_question
      all = enrollment_fields
      return all unless @question

      names = question_field_names(@question)
      return all if names.nil?

      all.slice(*names.map(&:to_s))
    end

    def question_field_names(question)
      mapped = extra_fields[question]
      if mapped.nil?
        Rails.logger.warn("[DrilldownPresenter] No field mapping for #{question.inspect} — showing all fields")
        return nil
      end

      (common_fields + mapped).uniq
    end

    def common_fields
      [
        :destination_client_id,
        :personal_id,
        :first_name,
        :last_name,
        :first_date_in_program,
        :last_date_in_program,
        :head_of_household,
      ].freeze
    end

    def extra_fields
      {
        'Question 4' => project_fields,
        'Question 5' => age_fields + parenting_fields + veteran_fields + homeless_fields,
        'Question 6' => pii_fields + universal_data_fields + financial_fields + housing_fields + project_fields + timeliness_fields + inactive_records_fields,
        'Question 7' => household_fields + parenting_fields + project_fields,
        'Question 8' => household_fields + parenting_fields + project_fields,
        'Question 9' => household_fields + parenting_fields + project_fields,
        'Question 10' => gender_fields + household_fields + age_fields + project_fields,
        'Question 11' => age_fields + household_fields + project_fields,
        'Question 12' => race_and_ethnicity_fields + household_fields + project_fields,
        'Question 13' => health_fields + household_fields + project_fields,
        'Question 14' => domestic_violence_fields + household_fields + project_fields,
        'Question 15' => housing_fields + household_fields,
        'Question 16' => financial_fields + age_fields + project_fields,
        'Question 17' => financial_fields + age_fields + project_fields,
        'Question 18' => financial_fields + age_fields + project_fields,
        'Question 19' => financial_fields + age_fields + health_fields + project_fields,
        'Question 20' => financial_fields + age_fields + parenting_fields + project_fields,
        'Question 21' => insurance_fields + project_fields,
        'Question 22' => housing_fields + household_fields + project_fields,
        'Question 23' => housing_fields + household_fields + project_fields,
        'Question 24' => household_fields + financial_fields + assessment_fields + housing_fields,
        'Question 25' => veteran_fields + household_fields + gender_fields + age_fields + health_fields + financial_fields + housing_fields + project_fields,
        'Question 26' => household_fields + homeless_fields + gender_fields + age_fields + health_fields + financial_fields + project_fields,
        'Question 27' => age_fields + household_fields + parenting_fields + gender_fields + health_fields + financial_fields + housing_fields + project_fields,
      }
    end

    def age_fields
      [:age, :dob]
    end

    def parenting_fields
      [:parenting_youth]
    end

    def veteran_fields
      [:veteran_status]
    end

    def homeless_fields
      [:chronically_homeless, :date_homeless, :times_homeless, :months_homeless]
    end

    def pii_fields
      [:ssn, :name_quality, :dob_quality, :ssn_quality, :race_multi, :sex]
    end

    def universal_data_fields
      [
        :veteran_status, :relationship_to_hoh, :enrollment_coc, :disabling_condition, :indefinite_and_impairs, :developmental_disability, :hiv_aids, :physical_disability, :chronic_disability, :mental_health_problem, :substance_abuse
      ]
    end

    def financial_fields
      [
        :income_date_at_start, :income_from_any_source_at_start, :income_from_any_source_at_start_raw, :income_sources_at_start, :income_date_at_annual_assessment, :annual_assessment_in_window, :income_from_any_source_at_annual_assessment, :income_from_any_source_at_annual_assessment_raw, :income_sources_at_annual_assessment, :income_date_at_exit, :income_from_any_source_at_exit, :income_from_any_source_at_exit_raw, :income_sources_at_exit, :income_total_at_start, :income_total_at_annual_assessment, :income_total_at_exit, :non_cash_benefits_from_any_source_at_start, :non_cash_benefits_from_any_source_at_annual_assessment, :non_cash_benefits_from_any_source_at_exit, :subsidy_information
      ]
    end

    def assessment_fields
      [
        :annual_assessment_expected, :housing_assessment, :annual_assessment_in_window, :ce_assessment_date, :ce_assessment_type, :ce_assessment_prioritization_status
      ]
    end

    def housing_fields
      [:destination, :housing_assessment, :prior_living_situation]
    end

    def project_fields
      [:project_type, :project_tracking_method]
    end

    def timeliness_fields
      [:enrollment_created, :exit_created]
    end

    def inactive_records_fields
      [:date_of_last_bed_night, :date_to_street]
    end

    def household_fields
      [
        :head_of_household, :head_of_household_id, :household_id, :household_type, :household_members, :move_in_date, :time_to_move_in, :date_to_street, :approximate_time_to_move_in
      ]
    end

    def gender_fields
      [:sex]
    end

    def race_and_ethnicity_fields
      [:race_multi]
    end

    def health_fields
      health_disability_fields.map { |f| f.name.to_sym }
    end

    def domestic_violence_fields
      [:domestic_violence, :currently_fleeing]
    end

    def insurance_fields
      [
        :insurance_from_any_source_at_start,
        :insurance_from_any_source_at_annual_assessment,
        :insurance_from_any_source_at_exit,
      ]
    end

    def ce_fields
      [
        :ce_assessment_date, :ce_assessment_type, :ce_assessment_prioritization_status, :ce_event_date, :ce_event_event, :ce_event_problem_sol_div_rr_result, :ce_event_referral_case_manage_after, :ce_event_referral_result
      ]
    end

    def health_disability_fields
      hiv_transform = ->(v, poly) { GrdaWarehouse::PiiProvider.viewable_hiv_status(v, policy: poly) }
      entry_exit_latest_only = ['alcohol_abuse', 'drug_abuse'].to_set
      [
        'mental_health_problem',
        'alcohol_abuse',
        'drug_abuse',
        'chronic_disability',
        'hiv_aids',
        'developmental_disability',
        'physical_disability',
        'substance_abuse',
      ].flat_map do |base|
        is_hiv = base == 'hiv_aids'
        transform = is_hiv ? hiv_transform : nil
        suffixes = entry_exit_latest_only.include?(base) ? ['_entry', '_exit', '_latest'] : [nil, '_entry', '_exit', '_latest']
        suffixes.map do |suffix|
          Field.new(name: "#{base}#{suffix}", transform: transform, pii: is_hiv)
        end
      end
    end

    def transform_value(field, value, _record, pii_policy)
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
        mode: html? ? :browse : :download,
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
  end
end
