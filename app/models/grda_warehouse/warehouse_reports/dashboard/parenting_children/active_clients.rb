module GrdaWarehouse::WarehouseReports::Dashboard::ParentingChildren
  class ActiveClients < GrdaWarehouse::WarehouseReports::Dashboard::Active

    def history_scope(scope)
      scope.parenting_juvenile
    end
  end
end