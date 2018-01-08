module GrdaWarehouse::WarehouseReports::Dashboard::ParentingYouth
  class EnteredClients < GrdaWarehouse::WarehouseReports::Dashboard::Entered

    def client_source
      GrdaWarehouse::Hud::Client.destination.
        parenting_youth(start_date: @start_date, end_date: @end_date)
    end

    def history_scope(scope)
      scope.parenting_youth
    end

  end
end