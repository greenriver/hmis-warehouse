module GrdaWarehouse::WarehouseReports::Dashboard::Youth
  class HousedClients < GrdaWarehouse::WarehouseReports::Dashboard::Housed

    def client_source
      GrdaWarehouse::Hud::Client.destination.youth(on: @start_date)
    end


  end
end