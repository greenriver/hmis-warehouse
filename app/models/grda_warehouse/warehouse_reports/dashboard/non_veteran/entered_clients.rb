module GrdaWarehouse::WarehouseReports::Dashboard::NonVeteran
  class EnteredClients < GrdaWarehouse::WarehouseReports::Dashboard::Entered

    def client_source
      GrdaWarehouse::Hud::Client.destination.non_veteran
    end


  end
end