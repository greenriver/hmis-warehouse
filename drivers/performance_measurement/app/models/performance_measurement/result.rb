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
  end
end
