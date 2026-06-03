# frozen_string_literal: true

module HudApr
  class DrilldownPresenter
    Field = Data.define(:name, :label, :transform, :not_collected, :pii, :groups) do
      def initialize(name:, label: nil, transform: nil, not_collected: nil, pii: nil, groups: [])
        super
      end
    end

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
        Field.new(name: 'personal_id', label: 'HMIS Personal ID', groups: [:common]),
        Field.new(name: 'first_name', transform: ->(v, poly) { GrdaWarehouse::PiiProvider.viewable_name(v, policy: poly) }, groups: [:common]),
        Field.new(name: 'last_name', transform: ->(v, poly) { GrdaWarehouse::PiiProvider.viewable_name(v, policy: poly) }, groups: [:common]),
        Field.new(name: 'destination_client_id', label: 'Warehouse Client ID', groups: [:common]),
        Field.new(name: 'ssn', label: 'SSN', transform: ->(v, poly) { GrdaWarehouse::PiiProvider.viewable_ssn(v, policy: poly) }, groups: [:pii]),
        Field.new(name: 'name_quality', label: 'Name Quality', transform: ->(v, _poly) { hud_helper.name_data_quality(v) }, groups: [:pii]),
        Field.new(name: 'ssn_quality', label: 'SSN Quality', transform: ->(v, _poly) { hud_helper.ssn_data_quality(v) }, groups: [:pii]),

        # Demographics
        Field.new(name: 'age', groups: [:age]),
        Field.new(name: 'dob', label: 'DOB', transform: ->(v, poly) { GrdaWarehouse::PiiProvider.viewable_dob(v, policy: poly) }, groups: [:age]),
        Field.new(name: 'dob_quality', label: 'DOB Quality', transform: ->(v, _poly) { hud_helper.dob_data_quality(v) }, not_collected: true, groups: [:pii]),
        Field.new(name: 'sex', transform: ->(v, _poly) { hud_helper.sex(v) }, not_collected: true, groups: [:pii, :gender]),
        Field.new(name: 'race_multi', label: 'Race', transform: ->(v, _poly) {
          next if v.nil?

          field_name = hud_helper.race_id_to_field_name[v.to_i]
          hud_helper.races[field_name.to_s] if field_name
        }, groups: [:pii, :race_ethnicity]),
        Field.new(name: 'veteran_status', transform: ->(v, _poly) { hud_helper.veteran_status(v) }, groups: [:veteran, :universal_data]),
        Field.new(name: 'relationship_to_hoh', label: 'Relationship to HoH', transform: ->(v, _poly) { hud_helper.relationship_to_hoh(v) }, groups: [:universal_data]),
        Field.new(name: 'disabling_condition', transform: ->(v, _poly) { hud_helper.disability_response(v) }, groups: [:universal_data]),
        Field.new(name: 'indefinite_and_impairs', groups: [:universal_data]),
        Field.new(name: 'sexual_orientation', transform: ->(v, _poly) { hud_helper.sexual_orientation(v) }),
        Field.new(name: 'preferred_language', transform: ->(v, _poly) { hud_helper.preferred_language(v) }),

        # Parenting
        Field.new(name: 'parenting_youth', groups: [:parenting]),
        Field.new(name: 'parenting_juvenile'),

        # Dates
        Field.new(name: 'first_date_in_program', groups: [:common]),
        Field.new(name: 'last_date_in_program', groups: [:common]),
        Field.new(name: 'date_of_engagement'),

        # Enrollment
        Field.new(name: 'enrollment_coc', label: 'Enrollment CoC', groups: [:universal_data]),

        # Household
        Field.new(name: 'head_of_household', groups: [:common, :household]),
        Field.new(name: 'head_of_household_id', groups: [:household]),
        Field.new(name: 'household_id', groups: [:household]),
        Field.new(name: 'household_type', groups: [:household]),
        Field.new(name: 'household_members', groups: [:household]),
        Field.new(name: 'move_in_date', label: 'Move-in Date', groups: [:household]),
        Field.new(name: 'hoh_move_in_date', label: 'HoH Move-in Date'),
        Field.new(name: 'time_to_move_in', groups: [:household]),
        Field.new(name: 'approximate_time_to_move_in', groups: [:household]),

        # Homeless history
        Field.new(name: 'chronically_homeless', groups: [:homeless]),
        Field.new(name: 'chronically_homeless_detail'),
        Field.new(name: 'prior_living_situation', transform: ->(v, _poly) { hud_helper.living_situation(v) }, groups: [:housing]),
        Field.new(name: 'prior_length_of_stay', transform: ->(v, _poly) { hud_helper.residence_prior_length_of_stay(v) }),
        Field.new(name: 'approximate_length_of_stay'),
        Field.new(name: 'came_from_street_last_night'),
        Field.new(name: 'date_homeless', groups: [:homeless]),
        Field.new(name: 'times_homeless', transform: ->(v, _poly) { hud_helper.times_homeless_past_three_years(v) }, groups: [:homeless]),
        Field.new(name: 'months_homeless', transform: ->(v, _poly) { hud_helper.months_homeless_past_three_years(v) }, groups: [:homeless]),
        Field.new(name: 'date_to_street', groups: [:household, :inactive_records]),
        Field.new(name: 'date_of_last_bed_night', groups: [:inactive_records]),

        # Health / Disability
        *health_disability_fields,

        # Domestic violence
        Field.new(name: 'domestic_violence', groups: [:domestic_violence]),
        Field.new(name: 'domestic_violence_occurred', label: 'When DV Occurred', transform: ->(v, _poly) { hud_helper.when_d_v_occurred(v) }),
        Field.new(name: 'currently_fleeing', groups: [:domestic_violence]),

        # Financial
        Field.new(name: 'income_date_at_start', groups: [:financial]),
        Field.new(name: 'income_from_any_source_at_start', groups: [:financial]),
        Field.new(name: 'income_from_any_source_at_start_raw', groups: [:financial]),
        Field.new(name: 'income_sources_at_start', groups: [:financial]),
        Field.new(name: 'income_date_at_annual_assessment', label: 'Income Date at Annual', groups: [:financial]),
        Field.new(name: 'annual_assessment_in_window', groups: [:financial, :assessment]),
        Field.new(name: 'income_from_any_source_at_annual_assessment', label: 'Income from Any Source at Annual', groups: [:financial]),
        Field.new(name: 'income_from_any_source_at_annual_assessment_raw', groups: [:financial]),
        Field.new(name: 'income_sources_at_annual_assessment', label: 'Income Sources at Annual', groups: [:financial]),
        Field.new(name: 'income_date_at_exit', groups: [:financial]),
        Field.new(name: 'income_from_any_source_at_exit', groups: [:financial]),
        Field.new(name: 'income_from_any_source_at_exit_raw', groups: [:financial]),
        Field.new(name: 'income_sources_at_exit', groups: [:financial]),
        Field.new(name: 'income_total_at_start', groups: [:financial]),
        Field.new(name: 'income_total_at_annual_assessment', label: 'Income Total at Annual', groups: [:financial]),
        Field.new(name: 'income_total_at_exit', groups: [:financial]),
        Field.new(name: 'non_cash_benefits_from_any_source_at_start', label: 'Non-cash Benefits at Start', groups: [:financial]),
        Field.new(name: 'non_cash_benefits_from_any_source_at_annual_assessment', label: 'Non-cash Benefits at Annual', groups: [:financial]),
        Field.new(name: 'non_cash_benefits_from_any_source_at_exit', label: 'Non-cash Benefits at Exit', groups: [:financial]),

        # Insurance
        Field.new(name: 'insurance_from_any_source_at_start', label: 'Insurance at Start', groups: [:insurance]),
        Field.new(name: 'insurance_from_any_source_at_annual_assessment', label: 'Insurance at Annual', groups: [:insurance]),
        Field.new(name: 'insurance_from_any_source_at_exit', label: 'Insurance at Exit', groups: [:insurance]),

        # Subsidy
        Field.new(name: 'subsidy_information', transform: ->(v, _poly) { hud_helper.subsidy_information(v) }, groups: [:financial]),
        Field.new(name: 'exit_destination_subsidy_type'),

        # Assessment
        Field.new(name: 'annual_assessment_expected', groups: [:assessment]),
        Field.new(name: 'housing_assessment', transform: ->(v, _poly) { hud_helper.housing_assessment_at_exit(v) }, not_collected: true, groups: [:assessment, :housing]),
        Field.new(name: 'ce_assessment_date', label: 'CE Assessment Date', groups: [:assessment, :ce]),
        Field.new(name: 'ce_assessment_type', label: 'CE Assessment Type', transform: ->(v, _poly) { hud_helper.assessment_type(v) }, groups: [:assessment, :ce]),
        Field.new(name: 'ce_assessment_prioritization_status', label: 'CE Prioritization Status', transform: ->(v, _poly) { hud_helper.prioritization_status(v) }, groups: [:assessment, :ce]),

        # Housing / Destination
        Field.new(name: 'destination', transform: ->(v, _poly) { hud_helper.destination(v) }, not_collected: true, groups: [:housing]),

        # Project
        Field.new(name: 'project_type', transform: ->(v, _poly) { hud_helper.project_type_brief(v) }, groups: [:project]),
        Field.new(name: 'project_tracking_method', groups: [:project]),

        # Timeliness
        Field.new(name: 'enrollment_created', groups: [:timeliness]),
        Field.new(name: 'exit_created', groups: [:timeliness]),

        # CE Events
        Field.new(name: 'ce_event_date', label: 'CE Event Date', groups: [:ce]),
        Field.new(name: 'ce_event_event', label: 'CE Event', groups: [:ce]),
        Field.new(name: 'ce_event_problem_sol_div_rr_result', label: 'CE Problem/Diversion/RR Result', groups: [:ce]),
        Field.new(name: 'ce_event_referral_case_manage_after', label: 'CE Referral Case Mgmt After', groups: [:ce]),
        Field.new(name: 'ce_event_referral_result', label: 'CE Referral Result', groups: [:ce]),
      ].index_by(&:name).freeze
    end

    def fields_for_question
      all = enrollment_fields
      return all unless @question

      groups = question_groups(@question)
      return all if groups.nil?

      all.select { |_name, field| (field.groups & groups).any? }
    end

    def question_groups(question)
      mapped = extra_fields[question]
      if mapped.nil?
        Rails.logger.warn("[DrilldownPresenter] No field mapping for #{question.inspect} — showing all fields")
        return nil
      end

      ([:common] + mapped).uniq
    end

    def extra_fields
      {
        'Question 4' => [:project],
        'Question 5' => [:age, :parenting, :veteran, :homeless],
        'Question 6' => [:pii, :universal_data, :financial, :housing, :project, :timeliness, :inactive_records],
        'Question 7' => [:household, :parenting, :project],
        'Question 8' => [:household, :parenting, :project],
        'Question 9' => [:household, :parenting, :project],
        'Question 10' => [:gender, :household, :age, :project],
        'Question 11' => [:age, :household, :project],
        'Question 12' => [:race_ethnicity, :household, :project],
        'Question 13' => [:health, :household, :project],
        'Question 14' => [:domestic_violence, :household, :project],
        'Question 15' => [:housing, :household],
        'Question 16' => [:financial, :age, :project],
        'Question 17' => [:financial, :age, :project],
        'Question 18' => [:financial, :age, :project],
        'Question 19' => [:financial, :age, :health, :project],
        'Question 20' => [:financial, :age, :parenting, :project],
        'Question 21' => [:insurance, :project],
        'Question 22' => [:housing, :household, :project],
        'Question 23' => [:housing, :household, :project],
        'Question 24' => [:household, :financial, :assessment, :housing],
        'Question 25' => [:veteran, :household, :gender, :age, :health, :financial, :housing, :project],
        'Question 26' => [:household, :homeless, :gender, :age, :health, :financial, :project],
        'Question 27' => [:age, :household, :parenting, :gender, :health, :financial, :housing, :project],
      }
    end

    UNIVERSAL_DATA_DISABILITIES = ['mental_health_problem', 'chronic_disability', 'hiv_aids', 'developmental_disability', 'physical_disability', 'substance_abuse'].to_set.freeze
    private_constant :UNIVERSAL_DATA_DISABILITIES

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
          groups = [:health]
          groups << :universal_data if suffix.nil? && UNIVERSAL_DATA_DISABILITIES.include?(base)
          Field.new(name: "#{base}#{suffix}", transform: transform, pii: is_hiv, groups: groups)
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
      @hud_helper ||= HudHelper.util
    end
  end
end
