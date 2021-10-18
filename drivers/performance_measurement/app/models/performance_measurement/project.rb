###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceMeasurement
  class Project < GrdaWarehouseBase
    self.table_name = :pm_projects
    acts_as_paranoid

    belongs_to :report

    scope :reporting_period, -> do
      where(reporting_period: true)
    end

    scope :comparison_period, -> do
      where(comparison_period: true)
    end
  end
end
