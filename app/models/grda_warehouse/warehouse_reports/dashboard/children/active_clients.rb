module GrdaWarehouse::WarehouseReports::Dashboard::Children
  class ActiveClients < GrdaWarehouse::WarehouseReports::Dashboard::Active

    def history_scope(scope)
      scope.children_only
    end

  end
end