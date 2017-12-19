module GrdaWarehouse::WarehouseReports::Dashboard::Veteran
  class HousedClients < GrdaWarehouse::WarehouseReports::Dashboard::Housed

    def client_source
      GrdaWarehouse::Hud::Client.destination.veteran
    end


  end
end