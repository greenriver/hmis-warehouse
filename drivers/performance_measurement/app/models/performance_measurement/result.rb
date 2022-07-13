###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceMeasurement
  class Result < GrdaWarehouseBase
    self.table_name = :pm_results
    acts_as_paranoid

    belongs_to :report
    belongs_to :project, primary_key: [:project_id, :report_id], foreign_key: [:project_id, :report_id], optional: true
    has_one :hud_project, through: :project

    scope :for_field, ->(field) do
      where(field: field)
    end

    scope :project, -> do
      where(system_level: false)
    end

    scope :system_level, -> do
      where(system_level: true)
    end

    def comparison_year
      report.filter.comparison_as_date_range.end.strftime('%Y')
    end

    def report_year
      report.filter.end.strftime('%Y')
    end

    def titles_for_system_level_bar_tooltip
      [report.filter.date_range_words, report.filter.comparison_range_words]
    end

    def percentage?
      primary_unit.starts_with?('%')
    end

    def max_100?
      field.starts_with?('returned')
    end

    def data_for_row
      this_year_count = primary_value.to_s
      this_year_count += ' %' if percentage?
      last_year_count = comparison_primary_value.to_s
      last_year_count += ' %' if percentage?
      OpenStruct.new(
        unit: primary_unit.sub('% ', ''),
        this_year_count: this_year_count,
        last_year_count: last_year_count,
        number_for_goal: goal_progress.round,
        goal: goal,
        goal_direction: report.detail_goal_direction(field),
        brief_goal_description: report.detail_goal_description_brief(field),
        goal_unit: report.detail_goal_unit(field),
        gauge_max: gauge_width,
        gauge_value: (goal_progress / max_for_gauge * gauge_width).round,
        gauge_target: (goal / max_for_gauge * gauge_width).round,
      )
    end

    private def gauge_width
      200
    end

    private def max_for_gauge
      [gauge_width, goal, goal_progress].max
    end

    def data_for_system_level_bar
      columns = if percentage?
        [
          ['x', report_year, comparison_year],
          [primary_unit, primary_value, comparison_primary_value],
        ]
      else
        [
          ['x', comparison_year, report_year],
          [primary_unit, comparison_primary_value, primary_value],
        ]
      end
      {
        x: 'x',
        columns: columns,
        type: 'bar',
        labels: {
          colors: 'white',
          centered: true,
        },
      }
    end

    def data_for_projects_bar(user, period: :reporting)
      value_column = if period == :reporting
        :primary_value
      else
        :comparison_primary_value
      end
      chart = {
        x: 'x',
        type: 'bar',
        labels: {
          colors: 'white',
          centered: true,
        },
      }
      projects = ['x']
      counts = [primary_unit]
      project_intermediate = []
      self.class.joins(:hud_project).
        preload(:hud_project).
        for_field(field).
        where(report_id: report_id).find_each do |result|
          count = result[value_column].round
          if count.positive?
            project_intermediate << [
              "#{result.hud_project.name(user, include_project_type: true)} (#{result.hud_project.id})",
              count,
            ]
          end
        end
      project_intermediate.sort_by(&:first).each do |project, count|
        projects << project
        counts << count
      end
      chart[:columns] = [
        projects,
        counts,
      ]
      chart
    end
  end
end
