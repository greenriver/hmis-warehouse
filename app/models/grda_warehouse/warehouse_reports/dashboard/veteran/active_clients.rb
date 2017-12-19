module GrdaWarehouse::WarehouseReports::Dashboard::Veteran
  class ActiveClients < GrdaWarehouse::WarehouseReports::Dashboard::Active

    def client_source
      GrdaWarehouse::Hud::Client.destination.veteran
    end


  end
end