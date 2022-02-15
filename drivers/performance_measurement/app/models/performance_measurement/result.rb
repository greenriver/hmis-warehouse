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

    def data_for_system_level_bar
      {
        x: 'x',
        columns: [
          ['x', report.filter.comparison_range_words, report.filter.date_range_words],
          [primary_unit, comparison_primary_value, primary_value],
        ],
        type: 'bar',
        labels: {
          colors: 'white',
          centered: true,
        },
      }
    end

    def data_for_projects_bar(period: :reporting)
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
              "#{result.hud_project.name_and_type} (#{result.hud_project.id})",
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
