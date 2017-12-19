module GrdaWarehouse::WarehouseReports::Dashboard::Youth
  class ActiveClients < GrdaWarehouse::WarehouseReports::Dashboard::Active

    def client_source
      GrdaWarehouse::Hud::Client.destination.youth(on: @range.start)
    end


  end
end