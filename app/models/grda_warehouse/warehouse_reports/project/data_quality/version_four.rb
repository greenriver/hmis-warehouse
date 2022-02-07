###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::WarehouseReports::Project::DataQuality
  class VersionFour < Base
    include ArelHelper
    include TsqlImport
    include ::Reporting::ProjectDataQualityReports::VersionFour::Display
    include ::Reporting::ProjectDataQualityReports::VersionFour::Support

    has_many :enrollments, class_name: 'Reporting::DataQualityReports::Enrollment', foreign_key: :report_id
    has_many :report_projects, class_name: 'Reporting::DataQualityReports::Project', foreign_key: :report_id
    has_one :report_project_group, class_name: 'Reporting::DataQualityReports::ProjectGroup', foreign_key: :report_id

    def run!
      progress_methods = [
        :start_report,
        :build_report_enrollments,
        :save_report_enrollments,
        :set_report_project_details,
        :save_report_project_details,
        :set_report_project_group_details,
        :save_report_project_group_details,
        :finish_report,
      ]
      progress_methods.each_with_index do |method, i|
        percent = ((i / progress_methods.size.to_f) * 100)
        percent = 0.01 if percent.zero?
        Rails.logger.info "Starting #{method}, #{percent.round(2)}% complete"
        send(method)
        Rails.logger.info "Completed #{method}"
      end
    end

    def report_range
      @report_range ||= ::Filters::DateRange.new(start: report_start, end: report_end)
    end

    def report_start
      start.to_date
    end

    def report_end
      self.end.to_date
    end

    def save_report_enrollments
      Reporting::DataQualityReports::Enrollment.transaction do
        Reporting::DataQualityReports::Enrollment.where(report_id: id).delete_all
        Reporting::DataQualityReports::Enrollment.import(@report_enrollments)
      end
    end

    def build_report_enrollments
      @report_enrollments = []
      source_enrollments.each do |hud_enrollment|
        client = hud_enrollment.client
        project = hud_enrollment.project
        hud_exit = hud_enrollment.exit

        report_enrollment = Reporting::DataQualityReports::Enrollment.new(
          report_id: id,
          client_id: client.id,
          project_id: project.id,
          project_name: project.ProjectName,
          project_type: project.computed_project_type,
          enrollment_id: hud_enrollment.id,
          enrolled: true,
          household_id: hud_enrollment.HouseholdID,
          dob: client.DOB,
          entry_date: hud_enrollment.EntryDate,
          move_in_date: hud_enrollment.MoveInDate,
          exit_date: hud_exit&.ExitDate,
          destination_id: hud_exit&.Destination,
          name_data_quality: client.NameDataQuality,
          ssn_data_quality: client.SSNDataQuality,
          dob_data_quality: client.DOBDataQuality,
          first_name: client.FirstName,
          last_name: client.LastName,
          ssn: client.SSN,
          gender_multi: client.gender_multi,
          veteran_status: client.VeteranStatus,
          disabling_condition: hud_enrollment.DisablingCondition,
          prior_living_situation: hud_enrollment.LivingSituation,
          ethnicity: client.Ethnicity,
          enrollment_date_created: hud_enrollment.DateCreated,
          exit_date_created: hud_exit&.DateCreated,

          calculated_at: started_at,
        )

        report_enrollment = set_calculated_fields(hud_enrollment: hud_enrollment, report_enrollment: report_enrollment)

        # per the HUD glossary, refused trumps missing, missing trumps partial
        # We're adding in not collected and complete so these need to be added in the following
        # order
        # refused, not collected, missing, partial, complete
        report_enrollment = set_completeness_fields(report_enrollment: report_enrollment, hud_enrollment: hud_enrollment, client: client, hud_exit: hud_exit)

        @report_enrollments << report_enrollment
      end
      return @report_enrollments
    end

    def set_calculated_fields(hud_enrollment:, report_enrollment:)
      project = hud_enrollment.project
      service_dates = service_dates_for_enrollment(hud_enrollment)
      exit_record = hud_enrollment.exit
      report_enrollment.head_of_household = report_enrollment.is_head_of_household?(enrollment: hud_enrollment)
      report_enrollment.active = report_enrollment.is_active?(
        project: project,
        service_dates: service_dates,
        report_start: report_start,
        report_end: report_end,
      )
      report_enrollment.entered = report_enrollment.is_entered?(
        entry_date: hud_enrollment.EntryDate,
        report_start: report_start,
        report_end: report_end,
      )
      report_enrollment.exited = report_enrollment.is_exited?(
        exit_record: exit_record,
        report_start: report_start,
        report_end: report_end,
      )
      report_enrollment.adult = report_enrollment.is_adult?(date: hud_enrollment.EntryDate)
      report_enrollment.household_type = household_type_for(enrollment: hud_enrollment)
      report_enrollment.age = report_enrollment.calculate_age(date: hud_enrollment.EntryDate)
      report_enrollment.days_to_add_entry_date = report_enrollment.calculate_days_to_add_entry_date(enrollment: hud_enrollment)
      report_enrollment.days_to_add_exit_date = report_enrollment.calculate_days_to_add_exit_date(exit_record: exit_record)
      report_enrollment.dob_after_entry_date = report_enrollment.calculate_dob_after_entry_date
      report_enrollment.most_recent_service_within_range = report_enrollment.calculate_most_recent_service_within_range(
        project: project,
        service_dates: service_dates,
        report_start: report_start,
        report_end: report_end,
        exit_date: exit_record&.ExitDate,
      )
      report_enrollment.service_within_last_30_days = report_enrollment.calculate_service_within_last_30_days(
        project: project,
        service_dates: service_dates,
        exit_date: exit_record&.ExitDate,
        report_end: report_end,
      )
      report_enrollment.service_after_exit = report_enrollment.calculate_service_after_exit(
        project: project,
        service_dates: service_dates,
        exit_date: exit_record&.ExitDate,
      )
      report_enrollment.days_of_service = report_enrollment.calculate_days_of_service(
        project: project,
        service_dates: service_dates,
        entry_date: hud_enrollment.EntryDate,
        exit_date: exit_record&.ExitDate,
        report_end: report_end,
      )

      report_enrollment.include_in_income_change_calculation = report_enrollment.should_calculate_income_change?(
        entry_date: hud_enrollment.EntryDate,
        head_of_household: report_enrollment.head_of_household,
      )
      # income at entry
      income_record_at_entry = income_at_entry_for_enrollment(hud_enrollment)
      report_enrollment.income_at_entry_earned = report_enrollment.calculate_income_at_entry_earned(
        income_at_entry: income_record_at_entry,
        entry_date: hud_enrollment.EntryDate,
        head_of_household: report_enrollment.head_of_household,
      )
      report_enrollment.income_at_entry_non_employment_cash = report_enrollment.calculate_income_at_entry_non_employment_cash(
        income_at_entry: income_record_at_entry,
        entry_date: hud_enrollment.EntryDate,
        head_of_household: report_enrollment.head_of_household,
      )
      report_enrollment.income_at_entry_overall = report_enrollment.calculate_income_at_entry_overall(
        income_at_entry: income_record_at_entry,
        entry_date: hud_enrollment.EntryDate,
        head_of_household: report_enrollment.head_of_household,
      )
      report_enrollment.income_at_entry_response = income_record_at_entry&.IncomeFromAnySource

      # Penultimate Income
      penultimate_income_record = report_enrollment.penultimate_income(incomes: hud_enrollment.income_benefits, report_end: report_end)
      report_enrollment.income_at_penultimate_earned = report_enrollment.calculate_income_at_penultimate_earned(
        income_record: penultimate_income_record,
        entry_date: hud_enrollment.EntryDate,
        head_of_household: report_enrollment.head_of_household,
        report_end: report_end,
      )
      report_enrollment.income_at_penultimate_non_employment_cash = report_enrollment.calculate_income_at_penultimate_non_employment_cash(
        income_record: penultimate_income_record,
        entry_date: hud_enrollment.EntryDate,
        head_of_household: report_enrollment.head_of_household,
        report_end: report_end,
      )
      report_enrollment.income_at_penultimate_overall = report_enrollment.calculate_income_at_penultimate_overall(
        income_record: penultimate_income_record,
        entry_date: hud_enrollment.EntryDate,
        head_of_household: report_enrollment.head_of_household,
        report_end: report_end,
      )
      report_enrollment.income_at_penultimate_response = penultimate_income_record&.IncomeFromAnySource

      # Income at later date
      later_income_record = report_enrollment.later_income(incomes: hud_enrollment.income_benefits, report_end: report_end)
      report_enrollment.income_at_later_date_earned = report_enrollment.calculate_income_at_later_date_earned(
        income_record: later_income_record,
        entry_date: hud_enrollment.EntryDate,
        head_of_household: report_enrollment.head_of_household,
        report_end: report_end,
      )
      report_enrollment.income_at_later_date_non_employment_cash = report_enrollment.calculate_income_at_later_date_non_employment_cash(
        income_record: later_income_record,
        entry_date: hud_enrollment.EntryDate,
        head_of_household: report_enrollment.head_of_household,
        report_end: report_end,
      )
      report_enrollment.income_at_later_date_overall = report_enrollment.calculate_income_at_later_date_overall(
        income_record: later_income_record,
        entry_date: hud_enrollment.EntryDate,
        head_of_household: report_enrollment.head_of_household,
        report_end: report_end,
      )
      report_enrollment.income_at_later_date_response = later_income_record&.IncomeFromAnySource

      # Income at annual date
      report_enrollment.should_have_income_annual_assessment = report_enrollment.should_calculate_annual_completeness?(
        entry_date: hud_enrollment.EntryDate,
        exit_date: hud_enrollment.exit&.ExitDate,
        head_of_household: report_enrollment.head_of_household,
        report_end: report_end,
      )
      annual_income_record = income_at_annual_for_enrollment(hud_enrollment)
      report_enrollment.income_at_annual_earned = report_enrollment.calculate_income_at_annual_earned(
        income_record: annual_income_record,
        entry_date: hud_enrollment.EntryDate,
        exit_date: hud_enrollment.exit&.ExitDate,
        head_of_household: report_enrollment.head_of_household,
        report_end: report_end,
      )
      report_enrollment.income_at_annual_non_employment_cash = report_enrollment.calculate_income_at_annual_non_employment_cash(
        income_record: annual_income_record,
        entry_date: hud_enrollment.EntryDate,
        exit_date: hud_enrollment.exit&.ExitDate,
        head_of_household: report_enrollment.head_of_household,
        report_end: report_end,
      )
      report_enrollment.income_at_annual_overall = report_enrollment.calculate_income_at_annual_overall(
        income_record: annual_income_record,
        entry_date: hud_enrollment.EntryDate,
        exit_date: hud_enrollment.exit&.ExitDate,
        head_of_household: report_enrollment.head_of_household,
        report_end: report_end,
      )
      report_enrollment.income_at_annual_response = annual_income_record&.IncomeFromAnySource

      report_enrollment.days_to_move_in_date = report_enrollment.calculate_days_to_move_in_date(
        entry_date: hud_enrollment.EntryDate,
        move_in_date: hud_enrollment.MoveInDate,
      )

      report_enrollment.days_ph_before_move_in_date = report_enrollment.calculate_days_in_ph_before_move_in_date(
        project_type: report_enrollment.project_type,
        entry_date: hud_enrollment.EntryDate,
        move_in_date: hud_enrollment.MoveInDate,
        report_end: report_end,
      )

      # depends on report_enrollment.household_type calculation from above
      report_enrollment.incorrect_household_type = report_enrollment.calculate_incorrect_household_type(
        household_type: report_enrollment.household_type,
        project: project,
      )

      return report_enrollment
    end

    def set_completeness_fields(report_enrollment:, hud_enrollment:, client:, hud_exit:)
      report_enrollment.set_name_completeness(
        first_name: client.FirstName,
        last_name: client.LastName,
        name_quality: client.NameDataQuality,
      )
      report_enrollment.set_ssn_completeness(
        ssn: client.SSN,
        ssn_quality: client.SSNDataQuality,
      )
      report_enrollment.set_dob_completeness(
        dob: client.DOB,
        dob_quality: client.DOBDataQuality,
        head_of_household: report_enrollment.head_of_household,
        entry_date: hud_enrollment.EntryDate,
        enrollment_created_date: hud_enrollment.DateCreated,
      )
      report_enrollment.set_gender_completeness(gender_none: client.GenderNone, gender_multi: client.gender_multi)
      report_enrollment.set_veteran_completeness(veteran: client.VeteranStatus, entry_date: hud_enrollment.EntryDate)
      report_enrollment.set_ethnicity_completeness(ethnicity: client.Ethnicity)
      report_enrollment.race = client.race_description
      report_enrollment.set_race_completeness(
        race_none: client.RaceNone,
        american_indian_or_ak_native: client.AmIndAKNative,
        asian: client.Asian,
        black_or_african_american: client.BlackAfAmerican,
        native_hi_or_other_pacific_islander: client.NativeHIPacific,
        white: client.White,
      )
      report_enrollment.set_disabling_condition_completeness(
        disabling_condition: hud_enrollment.DisablingCondition,
        all_indefinite_and_impairs: most_recent_disability_responses_for_enrollment(hud_enrollment),
      )
      report_enrollment.set_destination_completeness(
        hud_exit: hud_exit,
        head_of_household: report_enrollment.head_of_household,
      )
      report_enrollment.set_prior_living_situation_completeness(
        prior_living_situation: hud_enrollment.LivingSituation,
        head_of_household: report_enrollment.head_of_household,
      )
      report_enrollment.set_income_at_entry_completeness(
        income_at_entry: income_at_entry_for_enrollment(hud_enrollment),
      )
      report_enrollment.set_income_at_exit_completeness(
        income_at_exit: income_at_exit_for_enrollment(hud_enrollment),
        head_of_household: report_enrollment.head_of_household,
        exit_date: hud_enrollment.exit&.ExitDate,
        report_end: report_end,
      )
      report_enrollment.set_income_at_annual_completeness(
        entry_date: hud_enrollment.EntryDate,
        exit_date: hud_enrollment.exit&.ExitDate,
        income_record: income_at_annual_for_enrollment(hud_enrollment),
        head_of_household: report_enrollment.head_of_household,
        report_end: report_end,
      )
      return report_enrollment
    end

    def set_report_project_details
      @report_projects ||= []
      projects = GrdaWarehouse::Hud::Project.where(id: self.projects.map(&:id)).
        preload(:inventories, :geographies, :funders, :project_cocs)
      projects.each do |project|
        report_project = Reporting::DataQualityReports::Project.new(
          report_id: id,
          project_id: project.id,
          project_name: project.ProjectName,
          organization_name: project.organization.OrganizationName,
          project_type: project.computed_project_type,
          operating_start_date: project.OperatingStartDate,
          housing_type: project.HousingType,
          calculated_at: started_at,
        )

        report_project = set_project_calculated_fields(project: project, report_project: report_project)
        # These rely on calculations from above
        report_project = set_project_average_fields(report_project: report_project)

        @report_projects << report_project
      end
      return @report_projects
    end

    def set_project_calculated_fields(project:, report_project:)
      report_project.coc_code = report_project.calculate_coc_code(project: project)
      report_project.funder = report_project.calculate_funder(project: project)
      report_project.geocode = report_project.calculate_geocode(project: project)
      report_project.geography_type = report_project.calculate_geography_type(project: project)
      report_project.inventory_information_dates = report_project.calculate_inventory_information_dates(project: project)
      report_project.unit_inventory = report_project.calculate_unit_inventory(project: project, report_range: report_range)
      report_project.bed_inventory = report_project.calculate_bed_inventory(project: project, report_range: report_range)
      report_project.nightly_client_census = report_project.calculate_nightly_client_census(
        project: project,
        report_range: report_range,
      )
      report_project.nightly_household_census = report_project.calculate_nightly_household_census(
        project: project,
        report_range: report_range,
      )
      return report_project
    end

    # These rely on a set_project_calculated_fields being called first
    private def set_project_average_fields(report_project:) # rubocop:disable Naming/AccessorMethodName
      report_project.average_nightly_clients = report_project.calculate_average_nightly_clients(report_range: report_range)
      report_project.average_nightly_households = report_project.calculate_average_nightly_households(report_range: report_range)
      report_project.average_bed_utilization = report_project.calculate_average_bed_utilization
      report_project.average_unit_utilization = report_project.calculate_average_unit_utilization
      return report_project
    end

    def save_report_project_details
      Reporting::DataQualityReports::Project.transaction do
        Reporting::DataQualityReports::Project.where(report_id: id).delete_all
        Reporting::DataQualityReports::Project.import(@report_projects)
      end
    end

    def set_report_project_group_details
      project_ids = projects.map(&:id)
      @report_project_group = Reporting::DataQualityReports::ProjectGroup.new(
        report_id: id,
        calculated_at: started_at,
      )
      @report_project_group.unit_inventory = @report_project_group.calculate_unit_inventory(
        project_ids: project_ids,
        report_range: report_range,
      )
      @report_project_group.bed_inventory = @report_project_group.calculate_bed_inventory(
        project_ids: project_ids,
        report_range: report_range,
      )
      @report_project_group.nightly_client_census = @report_project_group.calculate_nightly_client_census(
        project_ids: project_ids,
        report_range: report_range,
      )
      @report_project_group.nightly_household_census = @report_project_group.calculate_nightly_household_census(
        project_ids: project_ids,
        report_range: report_range,
      )
      @report_project_group.average_nightly_clients = @report_project_group.calculate_average_nightly_clients(report_range: report_range)
      @report_project_group.average_nightly_households = @report_project_group.calculate_average_nightly_households(report_range: report_range)
      @report_project_group.average_bed_utilization = @report_project_group.calculate_average_bed_utilization
      @report_project_group.average_unit_utilization = @report_project_group.calculate_average_unit_utilization

      return @report_project_group
    end

    def save_report_project_group_details
      Reporting::DataQualityReports::ProjectGroup.transaction do
        Reporting::DataQualityReports::ProjectGroup.where(report_id: id).delete_all
        @report_project_group.save!
      end
    end

    # NOTE: since this is a report that is looking specifically at HMIS data quality
    # we are sticking to source data, including source clients
    def source_enrollments
      @source_enrollments ||= GrdaWarehouse::Hud::Enrollment.open_during_range(report_range).
        joins(:project, :client).
        preload(:exit, :client, :project, :income_benefits).
        merge(GrdaWarehouse::Hud::Project.where(id: projects.map(&:id)))
    end

    def exiters
      @exiters ||= source_enrollments.joins(:exit).
        where(ExitDate: (report_start..report_end))
    end

    # enrollments with joined/preloaded exits, keyed on enrollment id
    def exiters_by_enrollment_id
      @exiters_by_enrollment_id ||= exiters.index_by(&:id)
    end

    def exit_for_enrollment_id(id)
      exiters_by_enrollment_id[id].exit
    end

    def stayers
      @stayers ||= source_enrollments.where.not(id: exiters.select(:id))
    end

    def household_client_counts
      @household_client_counts ||= source_enrollments.where.not(HouseholdID: nil).
        group(:HouseholdID).
        count
    end

    def household_type_for(enrollment:)
      if household_client_counts[enrollment.HouseholdID].blank? || household_client_counts[enrollment.HouseholdID] == 1
        :individual
      else
        :family
      end
    end

    def service_dates_by_enrollment
      @service_dates_by_enrollment ||= begin
        dates_by_enrollment = {}
        source_enrollments.joins(:services).pluck(:id, Arel.sql(s_t[:DateProvided].to_sql)).each do |id, date|
          dates_by_enrollment[id] ||= []
          dates_by_enrollment[id] << date
        end
        # yield dates_by_enrollment
        dates_by_enrollment
      end
    end

    def service_dates_for_enrollment(enrollment)
      service_dates_by_enrollment[enrollment.id]&.compact || []
    end

    def most_recent_disability_responses_by_enrollment
      @most_recent_disability_responses_by_enrollment ||= begin
        responses_by_enrollment = {}
        columns = {
          enrollment_id: :id,
          date: d_t[:InformationDate].to_sql,
          type: d_t[:DisabilityType].to_sql,
          response: d_t[:DisabilityResponse].to_sql,
          indefinite_and_impairs: d_t[:IndefiniteAndImpairs].to_sql,
        }
        source_enrollments.joins(:disabilities).
          pluck(*columns.values.map { |column| Arel.sql(column.to_s) }).
          each do |row|
            row = Hash[columns.keys.zip(row)]
            responses_by_enrollment[row[:enrollment_id]] ||= {}
            responses_by_enrollment[row[:enrollment_id]][row[:date]] ||= []
            responses_by_enrollment[row[:enrollment_id]][row[:date]] << row
          end
        responses_by_enrollment.each do |enrollment_id, dates|
          # only keep the max date
          max_date = dates.keys.max
          data = dates[max_date]
          responses_by_enrollment[enrollment_id] = data
        end
        # yield the calculated hash
        responses_by_enrollment
      end
    end

    def most_recent_disability_responses_for_enrollment(enrollment)
      most_recent_disability_responses_by_enrollment[enrollment.id]
    end

    def incomes_at_entry_by_enrollment
      @incomes_at_entry_by_enrollment ||= begin
        incomes = {}
        source_enrollments.joins(:income_benefits_at_entry).
          preload(:income_benefits_at_entry).find_each do |enrollment|
            incomes[enrollment.id] = enrollment.income_benefits_at_entry
          end
        incomes
      end
    end

    def income_at_entry_for_enrollment(enrollment)
      incomes_at_entry_by_enrollment[enrollment.id]
    end

    def incomes_at_exit_by_enrollment
      @incomes_at_exit_by_enrollment ||= begin
        incomes = {}
        source_enrollments.joins(:income_benefits_at_exit).
          preload(:income_benefits_at_exit).find_each do |enrollment|
            incomes[enrollment.id] = enrollment.income_benefits_at_exit
          end
        incomes
      end
    end

    def income_at_exit_for_enrollment(enrollment)
      incomes_at_exit_by_enrollment[enrollment.id]
    end

    # most-recent income_benefit at annual update within the report range
    # indexed on HUD Enrollment.id
    def incomes_at_annual_by_enrollment
      @incomes_at_annual_by_enrollment ||= begin
        incomes = {}
        source_enrollments.joins(:income_benefits_annual_update).
          where(ib_t[:InformationDate].lteq(report_end)).
          preload(:income_benefits_annual_update).find_each do |enrollment|
            incomes[enrollment.id] = enrollment.income_benefits_annual_update.max_by(&:InformationDate)
          end
        incomes
      end
    end

    def income_at_annual_for_enrollment(enrollment)
      incomes_at_annual_by_enrollment[enrollment.id]
    end
  end
end
