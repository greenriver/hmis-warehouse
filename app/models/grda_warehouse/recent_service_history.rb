###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse
  class RecentServiceHistory < GrdaWarehouseBase
    self.table_name = :recent_service_history

    def readonly?
      true
    end

  end
end