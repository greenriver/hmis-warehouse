module GrdaWarehouse::WarehouseReports::Dashboard::AllClients
  class HousedClients < GrdaWarehouse::WarehouseReports::Dashboard::Housed

    def client_source
      GrdaWarehouse::Hud::Client.destination
    end


  end
end