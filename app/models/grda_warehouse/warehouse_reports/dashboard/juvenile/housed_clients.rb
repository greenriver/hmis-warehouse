###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::WarehouseReports::Dashboard::Juvenile
  class HousedClients < GrdaWarehouse::WarehouseReports::Dashboard::Housed

    def client_source
      GrdaWarehouse::Hud::Client.destination.
        juvenile(start_date: @start_date, end_date: @end_date)
    end


  end
end