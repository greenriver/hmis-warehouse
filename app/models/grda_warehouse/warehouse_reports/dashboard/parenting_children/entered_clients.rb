module GrdaWarehouse::WarehouseReports::Dashboard::ParentingChildren
  class EnteredClients < GrdaWarehouse::WarehouseReports::Dashboard::Entered

    def client_source
      GrdaWarehouse::Hud::Client.destination.
        parenting_juvenile(start_date: @start_date, end_date: @end_date)
    end

    def history_scope(scope)
      scope.parenting_juvenile
    end
  end
end