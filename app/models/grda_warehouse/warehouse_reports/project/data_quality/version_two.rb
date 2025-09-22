###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# DEPRECATED: VersionTwo is legacy code maintained only for displaying historical reports.
# New reports use VersionFour. Do not modify this class unless fixing critical bugs.
module GrdaWarehouse::WarehouseReports::Project::DataQuality
  class VersionTwo < Base
    MISSING_THRESHOLD = 10
    def run!
      start_report
      finish_report
    end

    def self.length_of_stay_buckets
      {
        '0 days' => (0..0),
        '1 week or less' => (1..6),
        '1 month or less' => (7..30),
        '1 to 3 months' => (31..90),
        '3 to 6 months' => (91..180),
        '6 to 9 months' => (181..271),
        '9 to 12 months' => (272..364),
        '1 year to 18 months' => (365..545),
        '18 months - 2 years' => (546..729),
        '2 - 5 years' => (730..1825),
        '5 years or more' => (1826..1.0 / 0),
      }
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
