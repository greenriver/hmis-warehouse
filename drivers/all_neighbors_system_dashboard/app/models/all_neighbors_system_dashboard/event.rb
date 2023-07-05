###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AllNeighborsSystemDashboard
  class Event < GrdaWarehouseBase
    acts_as_paranoid

    belongs_to :enrollment
  end
end
