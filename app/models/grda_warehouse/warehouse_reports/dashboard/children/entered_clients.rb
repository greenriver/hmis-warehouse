module GrdaWarehouse::WarehouseReports::Dashboard::Children
  class EnteredClients < GrdaWarehouse::WarehouseReports::Dashboard::Entered

    def client_source
      GrdaWarehouse::Hud::Client.destination.
        children_only(start_date: @start_date, end_date: @end_date)
    end

    def history_scope(scope)
      scope.children_only
    end
  end
end