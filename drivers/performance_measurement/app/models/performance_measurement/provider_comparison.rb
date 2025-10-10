###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module PerformanceMeasurement
  class ProviderComparison
    attr_accessor :report, :user
    def initialize(report, user)
      self.report = report
      self.user = user
    end

    def categories
      {
        'Emergency Shelters' => es_category,
        'Transitional Housing' => th_category,
        'Rapid Re-Housing' => rrh_category,
        'Permanent Supportive Housing' => psh_category,
        'Permanent Housing Only' => oph_category,
        'Street Outreach' => so_category,
      }
    end

    def table(category)
      definition = categories[category]
      raise "Category #{category} not found" unless definition

      table_data = {}
      # Headers
      table_data[:headers] = {}
      definition[:details].each do |detail|
        table_data[:headers][detail] = report.detail_title_for(detail)
      end
      # Fill in the system-wide data
      table_data[:system] = {}
      definition[:details].each do |detail|
        result = report.result_for(detail)

        table_data[:system][detail] = {
          value: result.primary_value,
          unit: result.primary_unit,
          passed: result.passed,
          goal: result.goal,
          goal_progress: result.goal_progress,
          goal_description: report.detail_goal_description_for(detail),
          decorator: decorator(result),
        }
      end
      # Fill in the project-level data

      table_data[:projects] = {}
      default_details = definition[:details].each_with_object({}) { |d, h| h[d] = {} }
      definition[:details].each do |detail|
        my_projects = report.my_projects(user, detail)
        my_projects.each do |project_id, result|
          # Initialize project with empty hashes for all details if not already set
          table_data[:projects][project_id] ||= {
            project_name: result.hud_project.name(user, include_project_type: true),
            values: default_details.deep_dup,
          }

          table_data[:projects][project_id][:values][detail] = {
            value: result.primary_value,
            unit: result.primary_unit,
            passed: result.passed,
            goal: result.goal,
            goal_progress: result.goal_progress,
            decorator: decorator(result),
          }
        end
      end
      table_data
    end

    def decorator(result)
      return '' if result.blank?
      return 'bg-success' if result.passed

      'bg-danger'
    end

    private def es_category
      {
        project_types: [0, 1],
        details: [
          :es_average_bed_utilization, # Average Bed Utilization
          :length_of_homeless_stay_average, # Length of Homeless Stay
          :retention_or_positive_destinations, # % of People Exits from ES, SH, TH, RRH to a Positive Destination, or PH with No Move-In
          :returned_in_two_years, # Percentage of People Who Returned to Homelessness Within Two Years
          :returned_in_one_year, # % of People Who Returned to Homelessness within 12 Months
          :returned_in_six_months, # % of People Who Returned to Homelessness within 6 Months
        ],
      }.freeze
    end

    private def th_category
      {
        project_types: [0, 1],
        details: [
          :th_average_bed_utilization, # Avg Bed Utilization
          :length_of_homeless_stay_average, # Length of Homeless Stay
          :retention_or_positive_destinations, # % of People Exits from ES, SH, TH, RRH to a Positive Destination, or PH with No Move-In
          :returned_in_two_years, # Percentage of People Who Returned to Homelessness Within Two Years
          :returned_in_one_year, # % of People Who Returned to Homelessness within 12 Months
          :returned_in_six_months, # % of People Who Returned to Homelessness within 6 Months
        ],
      }.freeze
    end

    private def rrh_category
      {
        project_types: [13],
        details: [
          :rrh_average_bed_utilization, # Avg Bed Utilization
          :time_to_move_in_average, # Length of Time to Move-In
          :retention_or_positive_destinations, # % of People Exits from ES, SH, TH, RRH to a Positive Destination, or PH with No Move-In
          :moved_in_positive_destinations, # Percentage of People in RRH or PH with Move-in or Permanent Exit
          :returned_in_two_years, # Percentage of People Who Returned to Homelessness Within Two Years
          :returned_in_one_year, # % of People Who Returned to Homelessness within 12 Months
          :returned_in_six_months, # % of People Who Returned to Homelessness within 6 Months
          :increased_income_all_clients, # Number of People with Increased Income
          :stayers_with_increased_income, # Stayer with Increased Income
          :stayers_with_increased_earned_income, # Stayer with Increased Earned Income
          :stayers_with_increased_non_cash_income, # Stayer with Increased Non-Employment Income
          :leavers_with_increased_income, # Leaver with Increased Income
          :leavers_with_increased_earned_income, # Leaver with Increased Earned Income
          :leavers_with_increased_non_cash_income, # Leaver with Increased Non-Employment Income
        ],
      }
    end

    private def psh_category
      {
        project_types: [3],
        details: [
          :psh_average_bed_utilization, # Avg Bed Utilization
          :time_to_move_in_average, # Length of Time to Move-In
          :retention_or_positive_destinations, # Percentage of People in RRH or PH with Move-in or Permanent Exit
          :returned_in_two_years, # Percentage of People Who Returned to Homelessness Within Two Years
          :returned_in_one_year, # % of People Who Returned to Homelessness within 12 Months
          :returned_in_six_months, # % of People Who Returned to Homelessness within 6 Months
          :increased_income_all_clients, # Number of People with Increased Income
          :stayers_with_increased_income, # Stayer with Increased Income
          :stayers_with_increased_earned_income, # Stayer with Increased Earned Income
          :stayers_with_increased_non_cash_income, # Stayer with Increased Non-Employment Income
          :leavers_with_increased_income, # Leaver with Increased Income
          :leavers_with_increased_earned_income, # Leaver with Increased Earned Income
          :leavers_with_increased_non_cash_income, # Leaver with Increased Non-Employment Income
        ],
      }
    end

    private def oph_category
      {
        project_types: [9, 10],
        details: [
          :oph_average_bed_utilization, # Avg Bed Utilization
          :time_to_move_in_average, # Length of Time to Move-In
          :retention_or_positive_destinations, # % of People in RRH or PH with Move-in or Permanent Exit
          :returned_in_two_years, # Percentage of People Who Returned to Homelessness Within Two Years
          :returned_in_one_year, # % of People Who Returned to Homelessness within 12 Months
          # :returned_in_six_months, # % of People Who Returned to Homelessness within 6 Months
        ],
      }
    end

    private def so_category
      {
        project_types: [4],
        details: [
          :so_positive_destinations, # % of People Exiting SO to a Positive Destination
          :returned_in_two_years, # Percentage of People Who Returned to Homelessness Within Two Years
          :returned_in_one_year, # % of People Who Returned to Homelessness within 12 Months
          :returned_in_six_months, # % of People Who Returned to Homelessness within 6 Months
          :increased_income_all_clients, # Number of People with Increased Income
          :leavers_with_increased_income, # Leaver with Increased Income
          :leavers_with_increased_earned_income, # Leaver with Increased Earned Income
          :leavers_with_increased_non_cash_income, # Leaver with Increased Non-Employment Income
        ],
      }.freeze
    end
  end
end
