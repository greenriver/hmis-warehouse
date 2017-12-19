module GrdaWarehouse::WarehouseReports::Dashboard::ParentingChildren
  class HousedClients < GrdaWarehouse::WarehouseReports::Dashboard::Housed

    def client_source
      GrdaWarehouse::Hud::Client.destination.
        parenting_juvenile(start_date: @start_date, end_date: @end_date)
    end


  end
end