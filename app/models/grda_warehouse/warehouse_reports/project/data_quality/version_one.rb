###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# DEPRECATED: VersionOne is legacy code maintained only for displaying historical reports.
# New reports use VersionFour. Do not modify this class unless fixing critical bugs.
module GrdaWarehouse::WarehouseReports::Project::DataQuality
  class VersionOne < Base
    MISSING_THRESHOLD = 10
    def run!
      start_report
      finish_report
    end

    def report_columns
      {
        total_clients: {
          title: 'Clients included',
        },
        total_leavers: {
          title: 'Leavers',
        },
        agency_name: {
          title: 'Agency name',
        },
        project_name: {
          title: 'Project name(s)',
        },
        monitoring_date_range: {
          title: 'Operating year (Funder start date and end date)',
        },
        monitoring_date_range_present: {
          title: 'Operating year present?',
          callback: :boolean,
        },
        grant_id: {
          title: 'Grant identification #',
        },
        coc_program_component: {
          title: 'CoC program component (project type)',
        },
        target_population: {
          title: 'Target population',
        },
        entering_required_data: {
          title: 'Is the agency entering the required data/descriptor touch-points into HMIS for this project?',
          callback: :boolean,
        },
        bed_coverage: {
          title: 'Bed coverage',
        },
        bed_coverage_percent: {
          title: 'Bed coverage',
          callback: :percent,
        },
        missing_name_percent: {
          title: 'Missing names',
          callback: :percent,
        },
        missing_ssn_percent: {
          title: 'Missing SSN',
          callback: :percent,
        },
        missing_dob_percent: {
          title: 'Missing DOB',
          callback: :percent,
        },
        missing_veteran_percent: {
          title: 'Missing veteran status',
          callback: :percent,
        },
        missing_ethnicity_percent: {
          title: 'Missing ethnicity',
          callback: :percent,
        },
        missing_race_percent: {
          title: 'Missing race',
          callback: :percent,
        },
        missing_gender_percent: {
          title: 'Missing gender',
          callback: :percent,
        },
        missing_disabling_condition_percentage: {
          title: 'Missing disabling condition',
          callback: :percent,
        },
        missing_prior_living_percentage: {
          title: 'Missing prior living',
          callback: :percent,
        },
        missing_destination_percentage: {
          title: 'Missing destination',
          callback: :percent,
        },
        refused_name_percent: {
          title: 'Refused name',
          callback: :percent,
        },
        refused_ssn_percent: {
          title: 'Refused SSN',
          callback: :percent,
        },
        refused_dob_percent: {
          title: 'Refused DOB',
          callback: :percent,
        },
        refused_veteran_percent: {
          title: 'Refused veteran status',
          callback: :percent,
        },
        refused_ethnicity_percent: {
          title: 'Refused ethnicity',
          callback: :percent,
        },
        refused_race_percent: {
          title: 'Refused race',
          callback: :percent,
        },
        refused_gender_percent: {
          title: 'Refused gender',
          callback: :percent,
        },
        refused_disabling_condition_percentage: {
          title: 'Refused disabling condition',
          callback: :percent,
        },
        refused_prior_living_percentage: {
          title: 'Refused prior living',
          callback: :percent,
        },
        refused_destination_percentage: {
          title: 'Refused destination',
          callback: :percent,
        },
        meets_dq_benchmark: {
          title: "Meets DQ Benchmark (all missing/refused < #{MISSING_THRESHOLD}%)",
          callback: :boolean,
        },
        one_year_enrollments: {
          title: 'Enrollments lasting 12 or more months',
        },
        one_year_enrollments_percentage: {
          title: 'Clients with enrollments lasting 12 or more months',
          callback: :percent,
        },
        ph_destinations: {
          title: 'Leavers who exited to PH',
        },
        ph_destinations_percentage: {
          title: 'Percentage of leavers who exited to PH',
        },
        increased_earned: {
          title: 'Clients with increased or retained earned income',
        },
        increased_earned_percentage: {
          title: 'Percentage of clients who had increased or retained  earned income',
          callback: :percent,
        },
        increased_non_cash: {
          title: 'Clients with increased or retained  non-cash income',
        },
        increased_non_cash_percentage: {
          title: 'Percentage of clients who had increased or retained  non-cash income',
          callback: :percent,
        },
        increased_overall: {
          title: 'Clients with increased or retained  overall income',
        },
        increased_overall_percentage: {
          title: 'Percentage of clients who had increased or retained  total income',
          callback: :percent,
        },
        services_provided: {
          title: 'Number of service events',
        },
        days_of_service: {
          title: 'Number of days in selected range',
        },
        average_daily_usage: {
          title: 'Average daily usage',
        },
        average_stay_length: {
          title: 'Average stay length',
          callback: :days,
        },
        capacity_percentage: {
          title: 'Percentage of beds in use, on average',
          callback: :percent,
        },
      }
    end
  end
end
