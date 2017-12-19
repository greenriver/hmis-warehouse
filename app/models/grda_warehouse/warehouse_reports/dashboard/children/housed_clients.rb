module GrdaWarehouse::WarehouseReports::Dashboard::Children
  class HousedClients < GrdaWarehouse::WarehouseReports::Dashboard::Housed

    def client_source
      GrdaWarehouse::Hud::Client.destination.
        children_only(start_date: @start_date, end_date: @end_date)
    end


  end
end