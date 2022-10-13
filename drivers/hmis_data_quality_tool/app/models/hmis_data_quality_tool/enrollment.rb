###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisDataQualityTool
  class Enrollment < ::HudReports::ReportClientBase
    self.table_name = 'hmis_dqt_enrollments'
    include ArelHelper
    include DqConcern
    include HudReports::Util
    include HudReports::Incomes
    include HudReports::Clients
    acts_as_paranoid

    attr_accessor :report_end_date

    has_many :hud_reports_universe_members, inverse_of: :universe_membership, class_name: 'HudReports::UniverseMember', foreign_key: :universe_membership_id
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', optional: true
    belongs_to :enrollment, class_name: 'GrdaWarehouse::Hud::Enrollment', optional: true

    def self.detail_headers
      {
        destination_client_id: 'Warehouse Client ID',
        hmis_enrollment_id: 'HMIS Enrollment ID',
        personal_id: 'HMIS Personal ID',
        project_name: 'Project Name',
        exit_id: 'HMIS Exit ID',
        entry_date: 'Entry Date',
        move_in_date: 'Move-in Date',
        exit_date: 'Exit Date',
        age: 'Reporting Age',
        household_max_age: 'Age of Oldest Household Member',
        household_id: 'Household ID',
        head_of_household_count: 'Count of Heads of Household',
        disabling_condition: 'Disabling Condition',
        living_situation: 'Living Situation',
        relationship_to_hoh: 'Relationship to Head of Household',
        coc_code: 'CoC Code',
        destination: 'Exit Destination',
        project_operating_start_date: 'Project Operating Start Date',
        project_operating_end_date: 'Project Operating End Date',
        project_type: 'Project Type',
        project_tracking_method: 'Project Tracking Method',
        lot: 'Length of Time in Project',
        days_since_last_service: 'Days Since Last Service',
      }.freeze
    end

    # Because multiple of these calculations require inspecting unrelated enrollments
    # we're going to loop over the entire enrollment scope once rather than
    # load it multiple times
    def self.calculate(report_items:, report:)
      enrollment_cache = new
      enrollment_scope(report).find_in_batches do |batch|
        intermediate = {}
        batch.each do |enrollment|
          item = enrollment_cache.report_item_fields_from_enrollment(
            report_items: report_items,
            enrollment: enrollment,
            report: report,
          )
          sections.each do |_, calc|
            section_title = calc[:title]
            intermediate[section_title] ||= {}
            intermediate[section_title][enrollment] = item if calc[:limiter].call(item)
          end
        end
        intermediate.each do |section_title, enrollment_batch|
          import_intermediate!(enrollment_batch.values)
          report.universe(section_title).add_universe_members(enrollment_batch) if enrollment_batch.present?

          report_items.merge!(enrollment_batch)
        end
      end
      report_items
    end

    def self.enrollment_scope(report)
      GrdaWarehouse::Hud::Enrollment.joins(:service_history_enrollment).
        left_outer_joins(:exit).
        preload(
          :exit,
          :project,
          :services,
          :current_living_situations,
          :enrollment_coc_at_entry,
          :disabilities_at_entry,
          :health_and_dvs_at_entry,
          :income_benefits_at_entry,
          :income_benefits_at_exit,
          :income_benefits_annual_update,
          client: :warehouse_client_source,
        ).
        merge(report.report_scope).distinct
    end

    # Instance method so we can take advantage of caching
    def report_item_fields_from_enrollment(report_items:, enrollment:, report:) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      # we only need to do the calculations once, the values will be the same for any enrollment,
      # no matter how many times we see it
      report_item = report_items[enrollment]
      return report_item if report_item.present?

      # To make the HudReport includes work
      @report = report
      self.report_end_date = report.filter.end_date

      client = enrollment.client
      report_item = self.class.new(
        report_id: report.id,
        enrollment_id: enrollment.id,
      )
      report_item.client_id = client.id
      report_item.personal_id = client.PersonalID
      report_item.destination_client_id = client.warehouse_client_source.destination_id
      report_item.hmis_enrollment_id = enrollment.EnrollmentID
      report_item.exit_id = enrollment.exit&.ExitID
      report_item.data_source_id = enrollment.data_source_id
      report_item.project_id = enrollment.project.id
      report_item.project_name = enrollment.project.name(report.user)
      report_item.project_type = enrollment.project.project_type_to_use
      report_item.entry_date = enrollment.EntryDate
      report_item.move_in_date = enrollment.MoveInDate
      report_item.exit_date = enrollment.exit&.ExitDate
      report_item.disabling_condition = enrollment.DisablingCondition
      report_item.household_id = enrollment.HouseholdID
      report_item.living_situation = enrollment.LivingSituation
      report_item.relationship_to_hoh = enrollment.RelationshipToHoH
      report_item.coc_code = enrollment.enrollment_coc_at_entry&.CoCCode
      report_item.destination = enrollment.exit&.Destination
      report_item.project_operating_start_date = enrollment.project.OperatingStartDate
      report_item.project_operating_end_date = enrollment.project.OperatingEndDate
      project_tracking_method = enrollment.project.TrackingMethod
      report_item.project_tracking_method = project_tracking_method
      report_age_date = [enrollment.EntryDate, report.filter.start].max
      report_item.age = enrollment.client.age_on(report_age_date)

      hh = report.household(enrollment.HouseholdID)
      hoh = hh.detect(&:head_of_household?) || enrollment
      # anniversary_date = anniversary_date(entry_date: hoh.first_date_in_program, report_end_date: report.end_date)
      hoh_annual_expected = annual_assessment_expected?(hoh)

      report_item.household_max_age = hh&.map(&:age)&.compact&.max || report_item.age
      report_item.household_min_age = hh&.map(&:age)&.compact&.min || report_item.age
      adult_or_hoh = enrollment.RelationshipToHoH == 1 || report_item.age.present? && report_item.age >= 18
      report_item.head_of_household_count = hh&.select(&:head_of_household?)&.count || 0
      report_item.household_type = household_type(report_item.household_min_age, report_item.household_max_age)

      report_item.ch_details_expected = adult_or_hoh
      report_item.health_dv_at_entry_expected = adult_or_hoh

      report_item.income_at_entry_expected = adult_or_hoh
      report_item.income_at_annual_expected = adult_or_hoh && hoh_annual_expected
      report_item.income_at_exit_expected = adult_or_hoh && enrollment&.exit&.ExitDate.present?

      report_item.insurance_at_entry_expected = true
      report_item.insurance_at_annual_expected = hoh_annual_expected
      report_item.insurance_at_exit_expected = enrollment&.exit&.ExitDate.present?

      report_item.los_under_threshold = enrollment.LOSUnderThreshold
      report_item.date_to_street_essh = enrollment.DateToStreetESSH
      report_item.times_homeless_past_three_years = enrollment.TimesHomelessPastThreeYears
      report_item.months_homeless_past_three_years = enrollment.MonthsHomelessPastThreeYears
      report_item.enrollment_coc = enrollment.enrollment_coc_at_entry&.CoCCode
      report_item.has_disability = enrollment.disabilities_at_entry&.indefinite_and_impairs?&.any?
      report_item.days_between_entry_and_create = (enrollment.EntryDate - enrollment.DateCreated.to_date).to_i

      report_item.domestic_violence_victim_at_entry = enrollment.health_and_dvs_at_entry&.first&.DomesticViolenceVictim

      entry_income_assessment = enrollment.income_benefits_at_entry
      annual_income_assessment = annual_assessment(enrollment, hoh.first_date_in_program)
      exit_income_assessment = enrollment.income_benefits_at_exit

      report_item.income_from_any_source_at_entry = entry_income_assessment&.IncomeFromAnySource
      report_item.income_from_any_source_at_annual = annual_income_assessment&.IncomeFromAnySource
      report_item.income_from_any_source_at_exit = exit_income_assessment&.IncomeFromAnySource

      report_item.cash_income_as_expected_at_entry = income_as_expected?(
        report_item.income_at_entry_expected,
        entry_income_assessment,
      )
      report_item.cash_income_as_expected_at_annual = income_as_expected?(
        report_item.income_at_annual_expected,
        annual_income_assessment,
      )
      report_item.cash_income_as_expected_at_exit = income_as_expected?(
        report_item.income_at_exit_expected,
        exit_income_assessment,
      )

      report_item.ncb_from_any_source_at_entry = entry_income_assessment&.BenefitsFromAnySource
      report_item.ncb_from_any_source_at_annual = annual_income_assessment&.BenefitsFromAnySource
      report_item.ncb_from_any_source_at_exit = exit_income_assessment&.BenefitsFromAnySource

      report_item.ncb_as_expected_at_entry = ncb_as_expected?(
        report_item.income_at_entry_expected,
        entry_income_assessment,
      )
      report_item.ncb_as_expected_at_annual = ncb_as_expected?(
        report_item.income_at_entry_expected,
        annual_income_assessment,
      )
      report_item.ncb_as_expected_at_exit = ncb_as_expected?(
        report_item.income_at_entry_expected,
        exit_income_assessment,
      )

      report_item.insurance_from_any_source_at_entry = entry_income_assessment&.InsuranceFromAnySource
      report_item.insurance_from_any_source_at_annual = annual_income_assessment&.InsuranceFromAnySource
      report_item.insurance_from_any_source_at_exit = exit_income_assessment&.InsuranceFromAnySource

      report_item.insurance_as_expected_at_entry = insurance_as_expected?(
        report_item.income_at_entry_expected,
        entry_income_assessment,
      )
      report_item.insurance_as_expected_at_annual = insurance_as_expected?(
        report_item.income_at_entry_expected,
        annual_income_assessment,
      )
      report_item.insurance_as_expected_at_exit = insurance_as_expected?(
        report_item.income_at_entry_expected,
        exit_income_assessment,
      )

      report_item.disability_at_entry_collected = enrollment.disabilities_at_entry&.map(&:DisabilityResponse)&.all? { |dr| dr.in?([0, 1]) } || false

      max_date = [report.filter.end, Date.current].min
      en_services = enrollment.services&.select { |s| s.DateProvided <= max_date }
      en_cls = enrollment.current_living_situations&.select { |s| s.InformationDate <= max_date }

      lot = if project_tracking_method == 3
        # count services <= min of report end and current date
        en_services.select(&:bed_night?)&.count || 0
      else
        # count dates between entry and min of report end, current_date, exit_date
        max_date = [enrollment.exit&.ExitDate, report.filter.end, Date.current].compact.min
        (max_date - enrollment.EntryDate).to_i
      end
      report_item.lot = lot
      end_date = [enrollment.exit&.ExitDate, report.filter.end, Date.current].compact.min
      max_service = if project_tracking_method == 3 # NbN ES
        # most recent service, or start date if no service
        en_services.max_by(&:DateProvided)&.DateProvided || enrollment.EntryDate
      elsif enrollment.project.project_type_to_use == 4 # SO
        # max CLS for SO, or start date if no CLS
        en_cls.max_by(&:InformationDate)&.InformationDate || enrollment.EntryDate
      else
        # min of exit date, report end, current date
        end_date
      end
      # count the days between the end of the earlier of the reporting end date or exit date and the most-recent service or the entry date
      report_item.days_since_last_service = (end_date - max_service).to_i
      report_item
    end

    private def household_type(min_age, max_age)
      return 'Unknown' if min_age.blank? || max_age.blank?
      return 'Adult Only' if min_age >= 18
      return 'Child Only' if max_age < 18

      'Adult and Child'
    end

    private def income_as_expected?(expected, assessment)
      return true unless expected

      valid = true
      assessment.all_sources_and_responses.each do |k, response|
        amount = assessment.all_sources_and_amounts[k]
        return false if response == 1 && ! amount.to_i.positive?
        return false if response&.zero? && amount.to_i.positive?
      end
      valid
    end

    private def ncb_as_expected?(expected, assessment)
      return true unless expected

      responses = assessment.values_at(*assessment.class::NON_CASH_BENEFIT_TYPES)
      return true if assessment.BenefitsFromAnySource == 1 && responses.include?(1)
      return true if assessment.BenefitsFromAnySource&.zero? && responses.all?(0)

      false
    end

    private def insurance_as_expected?(expected, assessment)
      return true unless expected

      responses = assessment.values_at(*assessment.class::INSURANCE_TYPES)
      return true if assessment.BenefitsFromAnySource == 1 && responses.include?(1)
      return true if assessment.BenefitsFromAnySource&.zero? && responses.all?(0)

      false
    end

    def self.sections
      {
        disabling_condition_issues: {
          title: 'Disabling Condition',
          description: 'Disabling condition is an invalid value',
          limiter: ->(item) {
            ! HUD.no_yes_reasons_for_missing_data_options.key?(item.disabling_condition)
          },
        },
        hoh_validation_issues: {
          title: 'Relationship to Head of Household',
          description: 'Relashionship to head of household is an invalid value',
          limiter: ->(item) {
            ! HUD.relationships_to_hoh.key?(item.relationship_to_hoh)
          },
        },
        living_situation_issues: {
          title: 'Living Situation',
          description: 'Living situation is an invalid value',
          limiter: ->(item) {
            return false if item.living_situation.blank?

            ! item.living_situation.in?(HUD.valid_prior_living_situations)
          },
        },
        exit_date_issues: {
          title: 'Exit before Entry',
          description: 'Enrollment exit date must occur after entry date',
          limiter: ->(item) {
            item.exit_date.present? && item.exit_date < item.entry_date
          },
        },
        destination_issues: {
          title: 'Destination',
          description: 'Destination is an invalid value',
          limiter: ->(item) {
            return false if item.exit_date.blank?

            ! HUD.valid_destinations.key?(item.destination)
          },
        },
        unaccompanied_youth_issues: {
          title: 'Unaccompanied Youth < 12 Years Old',
          description: 'Youth under 12 are generally expected to be accompanied.  The presence of an unaccompanied youth under 12 may indicate an issue with household data collection',
          limiter: ->(item) {
            item.household_max_age.present? && item.household_max_age < 12
          },
        },
        no_hoh_issues: {
          title: 'No Head of Household',
          description: 'Every household must have exactly one head of household',
          limiter: ->(item) {
            item.head_of_household_count.zero?
          },
        },
        multiple_hoh_issues: {
          title: 'Multiple Heads of Household',
          description: 'Every household must have exactly one head of household',
          limiter: ->(item) {
            item.head_of_household_count > 1
          },
        },
        hoh_client_location_issues: {
          title: 'Head of Household is Missing Client Location',
          description: 'Client location (CoC Code) is collection is required for all heads of household',
          limiter: ->(item) {
            item.relationship_to_hoh == 1 && item.coc_code.blank? && HUD.valid_coc?(item.coc_code)
          },
        },
        future_exit_date_issues: {
          title: 'Future Exit Date',
          description: 'Exit dates should be entered on or after the exit date',
          limiter: ->(item) {
            item.exit_date.present? && item.exit_date > Date.current
          },
        },
        days_since_last_service_es_90_issues: {
          title: 'Possible Missed Exit - ES, Time in Enrollment 90 Days or More',
          description: 'There is an expectation that clients will not stay indefinitely in emergency shelter, these clients have been in shelter more than 90 days',
          limiter: ->(item) {
            item.lot > 90 && GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:es].include?(item.project_type)
          },
        },
        days_since_last_service_es_180_issues: {
          title: 'Possible Missed Exit - ES, Time in Enrollment 180 Days or More',
          description: 'There is an expectation that clients will not stay indefinitely in emergency shelter, these clients have been in shelter more than 180 days',
          limiter: ->(item) {
            item.lot > 180 && GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:es].include?(item.project_type)
          },
        },
        days_since_last_service_es_365_issues: {
          title: 'Possible Missed Exit - ES, Time in Enrollment 365 Days or More',
          description: 'There is an expectation that clients will not stay indefinitely in emergency shelter, these clients have been in shelter more than 365 days',
          limiter: ->(item) {
            item.lot > 365 && GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:es].include?(item.project_type)
          },
        },
        days_since_last_service_so_90_issues: {
          title: 'Possible Missed Exit - SO, Time in Enrollment 90 Days or More',
          description: 'There is an expectation that clients will not stay indefinitely in street outreach, these clients have been in street outreach with no current living situation collected for more than 90 days',
          limiter: ->(item) {
            item.days_since_last_service > 90 && GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:so].include?(item.project_type)
          },
        },
        days_since_last_service_so_180_issues: {
          title: 'Possible Missed Exit - SO, Time in Enrollment 180 Days or More',
          description: 'There is an expectation that clients will not stay indefinitely in street outreach, these clients have been in street outreach with no current living situation collected for more than 180 days',
          limiter: ->(item) {
            item.days_since_last_service > 180 && GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:so].include?(item.project_type)
          },
        },
        days_since_last_service_so_365_issues: {
          title: 'Possible Missed Exit - SO, Time in Enrollment 365 Days or More',
          description: 'There is an expectation that clients will not stay indefinitely in street outreach, these clients have been in street outreach with no current living situation collected for more than 365 days',
          limiter: ->(item) {
            item.days_since_last_service > 365 && GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:so].include?(item.project_type)
          },
        },
        days_in_ph_prior_to_move_in_90_issues: {
          title: 'Possible Missed Move In Date - PH, Time in Enrollment 90 Days or More',
          description: 'There is an expectation that clients in PH will eventually move into housing, these clients have been in PH without a move-in date more than 90 days, or have an invalid move-in date ',
          limiter: ->(item) {
            return false if item.move_in_date.present? && item.move_in_date >= item.entry_date && (item.exit_date.blank? || item.move_in_date <= item.exit_date)

            item.lot > 90 && GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph].include?(item.project_type)
          },
        },
        days_in_ph_prior_to_move_in_180_issues: {
          title: 'Possible Missed Move In Date - PH, Time in Enrollment 180 Days or More',
          description: 'There is an expectation that clients in PH will eventually move into housing, these clients have been in PH without a move-in date more than 180 days, or have an invalid move-in date',
          limiter: ->(item) {
            return false if item.move_in_date.present? && item.move_in_date >= item.entry_date && (item.exit_date.blank? || item.move_in_date <= item.exit_date)

            item.lot > 180 && GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph].include?(item.project_type)
          },
        },
        days_in_ph_prior_to_move_in_365_issues: {
          title: 'Possible Missed Move In Date - PH, Time in Enrollment 365 Days or More',
          description: 'There is an expectation that clients in PH will eventually move into housing, these clients have been in PH without a move-in date more than 365 days, or have an invalid move-in date',
          limiter: ->(item) {
            return false if item.move_in_date.present? && item.move_in_date >= item.entry_date && (item.exit_date.blank? || item.move_in_date <= item.exit_date)

            item.lot > 365 && GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph].include?(item.project_type)
          },
        },
        move_in_prior_to_start_issues: {
          title: 'Move-In Before Entry Date',
          description: 'Move-in date must be on or after the entry date, only checked for PH projects',
          limiter: ->(item) {
            return false if item.move_in_date.blank?
            return false unless GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph].include?(item.project_type)

            item.move_in_date < item.entry_date
          },
        },
        move_in_post_exit_issues: {
          title: 'Move-In After Exit Date',
          description: 'Move-in date must be on or before the exit date, only checked for PH projects',
          limiter: ->(item) {
            return false if item.move_in_date.blank? || item.exit_date.blank?
            return false unless GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph].include?(item.project_type)

            item.move_in_date > item.exit_date
          },
        },
        enrollment_outside_project_operating_dates_issues: {
          title: 'Enrollment Active Outside of Project Operating Dates',
          description: 'Entry and exit dates must occur while a project is in operation',
          limiter: ->(item) {
            start_date = item.project_operating_start_date || '2000-01-01'.to_date
            end_date = item.project_operating_end_date || Date.current
            ! item.entry_date.between?(start_date, end_date) &&
            (item.exit_date.present? && ! item.exit_date.between?(start_date, end_date))
          },
        },
      }.freeze
    end
  end
end
