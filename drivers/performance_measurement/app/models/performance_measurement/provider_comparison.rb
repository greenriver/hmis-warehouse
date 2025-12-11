###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module PerformanceMeasurement
  class ProviderComparison
    include ArelHelper
    attr_accessor :report, :user, :active_project_list
    def initialize(report, user, active_project_list: :my_projects)
      self.report = report
      self.user = user
      self.active_project_list = active_project_list.to_sym
    end

    # Hex colors used for Excel fills to mirror UI status colors
    SUCCESS_HEX = 'E0F5EE'
    WARNING_HEX = 'FFEFC7'
    DANGER_HEX = 'EEA6AA'

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

    def included_categories
      @included_categories ||= categories.select do |_, definition|
        (included_project_types & definition[:project_types]).any?
      end
    end

    def table(category)
      definition = categories[category]
      raise "Category #{category} not found" unless definition

      table_data = {}
      # Headers
      table_data[:headers] = {}
      definition[:details].each do |detail|
        table_data[:headers][detail] = {
          title: report.detail_title_for(detail),
          category: report.detail_category_for(detail),
        }
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
          goal_description: formatted_goal_description(detail),
          tooltip: report.detail_goal_description_for(detail),
          decorator: decorator(result, detail),
          decorator_bg_color: decorator_bg_color(result, detail),
          display_value: display_value(result, detail),
        }
      end
      # Fill in the project-level data

      table_data[:projects] = {}
      default_details = definition[:details].each_with_object({}) { |d, h| h[d] = {} }
      definition[:details].each do |detail|
        # retention_or_positive_destinations is a system-level metric made up of 3 project-level metrics, we need to treat it differently.
        if detail == :retention_or_positive_destinations
          project_contributions_for_retention(user, definition).each do |project_id, info|
            # Initialize project with empty hashes for all details if not already set
            table_data[:projects][project_id] ||= {
              project_name: info[:project_name],
              values: default_details.deep_dup,
            }

            table_data[:projects][project_id][:values][detail] = {
              value: info[:value],
              unit: info[:unit],
              passed: info[:passed],
              goal: info[:goal],
              decorator: info[:decorator],
              decorator_bg_color: info[:decorator_bg_color],
              display_value: info[:display_value],
            }
          end
        else
          project_list(user, detail).each do |project_id, result|
            next unless result.hud_project.project_type.in?(definition[:project_types])

            # Initialize project with empty hashes for all details if not already set
            table_data[:projects][project_id] ||= {
              project_name: result.hud_project.name(user, include_project_type: true),
              values: default_details.deep_dup,
            }

            table_data[:projects][project_id][:values][detail] = {
              value: result.primary_value.presence,
              unit: result.primary_unit,
              passed: result.passed,
              goal: result.goal,
              decorator: decorator(result, detail),
              decorator_bg_color: decorator_bg_color(result, detail),
              display_value: display_value(result, detail),
            }
          end
        end
      end
      table_data
    end

    def project_list(user, detail)
      case @active_project_list
      when :my_projects
        report.my_projects(user, detail)
      when :all_projects
        report.project_details(user, detail)
      else
        raise "Unknown project list: #{@active_project_list}"
      end
    end

    def decorator(result, detail)
      return '' if result.blank?
      return 'performance-measurement--td-status success' if result.passed
      return 'performance-measurement--td-status warning' if approaching?(result, detail)

      'performance-measurement--td-status danger'
    end

    def decorator_bg_color(result, detail)
      return nil if result.blank?
      # Matches HTML intent of success/danger backgrounds
      # success → --brand-success-lll, danger → --brand-danger-lll
      return SUCCESS_HEX if result.passed

      return DANGER_HEX unless approaching?(result, detail)

      # warning → --brand-warning-lll (approximate hex)
      WARNING_HEX
    end

    private def included_project_types
      @included_project_types ||= report.results.joins(:hud_project).distinct.pluck(p_t[:ProjectType])
    end

    private def project_contributions_for_retention(user, definition)
      sub_fields = [
        :so_positive_destinations,
        :es_sh_th_rrh_positive_destinations,
        :moved_in_positive_destinations,
      ]
      contributions = {}
      sub_fields.each do |sub_field|
        report.project_details(user, sub_field).each do |project_id, sub_result|
          next unless sub_result.hud_project.project_type.in?(definition[:project_types])

          # Take the first contributing sub-result per project (projects should only appear once)
          next if contributions.key?(project_id)

          contributions[project_id] = {
            sub_field: sub_field,
            sub_result: sub_result,
          }
        end
      end
      contributions.transform_values do |info|
        sub_result = info[:sub_result]
        decorator_class = decorator(sub_result, info[:sub_field])
        {
          project_name: sub_result.hud_project.name(user, include_project_type: true),
          value: sub_result.primary_value.presence,
          unit: sub_result.primary_unit,
          passed: sub_result.passed,
          goal: sub_result.goal,
          decorator: decorator_class,
          decorator_bg_color: decorator_bg_color(sub_result, info[:sub_field]),
          display_value: display_value(sub_result, info[:sub_field]),
        }
      end
    end

    private def formatted_goal_description(detail)
      description = report.detail_specific_target_for(detail)
      return description unless detail.to_s.include?('increased_')

      "increase #{description}"
    end

    private def display_value(result, detail)
      value = "#{result.primary_value} #{result.primary_unit}"
      value = "#{result.primary_value}#{result.primary_unit}" if result.primary_unit.include?('%')
      # For increased income metrics, show the prior year value so we can show the current year goal as an absolute number
      # For example, if the goal is to increase income of at least 3% of adults, and last year they had 6% of adults had increased income,
      # we want to show a goal of 9% of clients (Prior Year: 6%)
      value = "#{value} (Prior Year: #{result.comparison_primary_value}#{result.secondary_unit})" if detail.to_s.include?('increased_')
      value
    end

    private def approaching?(result, detail)
      threshold_fraction = report.goal_config&.approaching_threshold_fraction
      return false unless threshold_fraction&.positive?

      goal_value = result.goal
      primary_value = result.primary_value
      return false unless goal_value.present? && primary_value.present?

      direction = report.detail_goal_direction(detail).to_s.strip
      case direction
      when '>'
        # Failed but within threshold below the goal
        primary_value < goal_value && primary_value >= goal_value * (1.0 - threshold_fraction)
      when '<'
        # Failed but within threshold above the goal
        primary_value > goal_value && primary_value <= goal_value * (1.0 + threshold_fraction)
      else
        false
      end
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
        project_types: [2],
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
