module GrdaWarehouse::WarehouseReports::Dashboard::Children
  class EnteredClients < GrdaWarehouse::WarehouseReports::Dashboard::Entered

    def history_scope(scope)
      scope.children_only
    end
  end
end