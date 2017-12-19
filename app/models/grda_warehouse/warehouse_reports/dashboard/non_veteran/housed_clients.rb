module GrdaWarehouse::WarehouseReports::Dashboard::NonVeteran
  class HousedClients < GrdaWarehouse::WarehouseReports::Dashboard::Housed

    def client_source
      GrdaWarehouse::Hud::Client.destination.non_veteran
    end


  end
end