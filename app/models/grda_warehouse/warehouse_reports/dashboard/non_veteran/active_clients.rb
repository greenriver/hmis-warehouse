module GrdaWarehouse::WarehouseReports::Dashboard::NonVeteran
  class ActiveClients < GrdaWarehouse::WarehouseReports::Dashboard::Active

    def client_source
      GrdaWarehouse::Hud::Client.destination.non_veteran
    end


  end
end