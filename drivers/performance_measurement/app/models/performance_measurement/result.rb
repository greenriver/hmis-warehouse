###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceMeasurement
  class Result < GrdaWarehouseBase
    self.table_name = :pm_results
    acts_as_paranoid

    belongs_to :report
    belongs_to :hud_project, class_name: 'GrdaWarehouse::Hud::Project', foreign_key: :project_id, optional: true

    scope :for_field, ->(field) do
      where(field: field)
    end

    scope :project, -> do
      where(system_level: false)
    end

    scope :system_level, -> do
      where(system_level: tru)
    end

    def data_for_system_level_bar
      {
        x: 'x',
        columns: [
          ['x', report.filter.comparison_range_words, report.filter.date_range_words],
          [primary_unit, comparison_primary_value, primary_value],
        ],
        type: 'bar',
      }
    end
  end
end
