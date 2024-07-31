###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceMeasurement
  class StaticSpm < GrdaWarehouseBase
    self.table_name = :pm_coc_static_spms
    acts_as_paranoid

    belongs_to :goal
  end
end
