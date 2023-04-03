###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
module GrdaWarehouse
  class RecentItem < GrdaWarehouseBase
    belongs_to :owner, polymorphic: true
    belongs_to :item, polymorphic: true
  end
end
