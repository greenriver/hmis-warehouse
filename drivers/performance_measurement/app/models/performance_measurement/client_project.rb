###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PerformanceMeasurement
  class ClientProject < GrdaWarehouseBase
    acts_as_paranoid

    belongs_to :client
  end
end
