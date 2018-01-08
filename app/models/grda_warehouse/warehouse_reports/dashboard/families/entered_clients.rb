module GrdaWarehouse::WarehouseReports::Dashboard::Families
  class EnteredClients < GrdaWarehouse::WarehouseReports::Dashboard::Entered

    def client_source
      GrdaWarehouse::Hud::Client.destination.family(start_date: @start_date, end_date: @end_date)
    end

    def history_scope(scope)
      scope.family
    end
    
  end
end