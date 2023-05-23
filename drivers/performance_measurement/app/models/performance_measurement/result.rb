###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceMeasurement
  class Result < GrdaWarehouseBase
    include ActionView::Helpers::NumberHelper
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
      [report.filter.comparison_range_words, report.filter.date_range_words]
    end

    def pit_count
      @pit_count ||= report.goal_config.pit_counts.where(pit_date: report.filter.range).max_by(&:pit_date)
    end

    def comparison_pit_count
      @comparison_pit_count ||= report.goal_config.pit_counts.where(pit_date: report.filter.comparison_range).max_by(&:pit_date)
    end

    def percentage?
      primary_unit.starts_with?('%')
    end

    def max_100?
      field.starts_with?('returned')
    end

    def data_for_row
      this_year_count = number_with_delimiter(primary_value).to_s
      this_year_count += ' %' if percentage?
      last_year_count = number_with_delimiter(comparison_primary_value).to_s
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
      average_metric = field.to_s.ends_with?('_average')
      unit = if average_metric
        'average days'
      else
        primary_unit
      end
      columns = [
        [
          'x',
          comparison_year,
          report_year,
        ],
        [
          unit,
          comparison_primary_value,
          primary_value,
        ],
      ]
      if average_metric
        columns << [
          'median days',
          related_median.comparison_primary_value,
          related_median.primary_value,
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

    def includes_median?
      field.to_s.ends_with?('_average')
    end

    def related_median
      @related_median = report.results.find_by(field: related_median_field, project_id: project_id)
    end

    private def related_median_field
      field.gsub('_average', '_median')
    end

    def data_for_projects_bar(user)
      chart = {
        x: 'x',
        type: 'bar',
        labels: {
          colors: 'white',
          centered: true,
        },
      }
      projects = ['x']
      unit = primary_unit
      unit = "Average #{unit}" if includes_median?
      counts = [unit]
      median_counts = ["Median #{primary_unit}"] if includes_median?
      project_intermediate = []
      median_intermediate = {}
      self.class.joins(:hud_project).
        preload(:hud_project).
        for_field(field).
        where(report_id: report_id).find_each do |result|
          count = result[:primary_value].round
          if count.positive?
            project_intermediate << [
              "#{result.hud_project.name(user, include_project_type: true)} (#{result.hud_project.id})",
              count,
            ]
          end
        end
      if includes_median?
        self.class.joins(:hud_project).
          preload(:hud_project).
          for_field(related_median_field).
          where(report_id: report_id).find_each do |result|
            count = result[:primary_value].round
            if count.positive?
              project_name = "#{result.hud_project.name(user, include_project_type: true)} (#{result.hud_project.id})"
              median_intermediate[project_name] = count
            end
          end
      end
      project_intermediate.sort_by(&:first).each do |project, count|
        projects << project
        counts << count
        median_counts << median_intermediate[project] if includes_median?
      end
      chart[:columns] = [
        projects,
        counts,
      ]
      chart[:columns] << median_counts if includes_median?
      chart
    end

    def tagged?
      # For now, all system-level need tagging
      return true if system_level

      untagged = report.detail_for(field)[:untagged]
      return false if untagged

      true
    end
  end
end
