###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientLocationHistory
  class Location < GrdaWarehouseBase
    belongs_to :source, polymorphic: true
  end
end
