module GrdaWarehouse::WarehouseReports::Dashboard::Youth
  class EnteredClients < GrdaWarehouse::WarehouseReports::Dashboard::Entered

    def client_source
      GrdaWarehouse::Hud::Client.destination.youth(on: @start_date)
    end


  end
end