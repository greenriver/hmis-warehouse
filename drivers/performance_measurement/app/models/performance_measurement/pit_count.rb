###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceMeasurement
  class PitCount < GrdaWarehouseBase
    acts_as_paranoid

    belongs_to :goal
  end
end
