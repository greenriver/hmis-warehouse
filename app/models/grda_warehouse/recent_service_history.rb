###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class RecentServiceHistory < GrdaWarehouseBase
    self.table_name = :recent_service_history

    def readonly?
      true
    end
  end
end
