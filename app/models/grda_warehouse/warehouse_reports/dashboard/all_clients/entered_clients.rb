module GrdaWarehouse::WarehouseReports::Dashboard::AllClients
  class EnteredClients < GrdaWarehouse::WarehouseReports::Dashboard::Entered

    def client_source
      GrdaWarehouse::Hud::Client.destination
    end


  end
end