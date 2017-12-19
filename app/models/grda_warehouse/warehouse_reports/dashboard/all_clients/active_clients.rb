module GrdaWarehouse::WarehouseReports::Dashboard::AllClients
  class ActiveClients < GrdaWarehouse::WarehouseReports::Dashboard::Active

    def client_source
      GrdaWarehouse::Hud::Client.destination
    end


  end
end