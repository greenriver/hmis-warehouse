module GrdaWarehouse::WarehouseReports::Dashboard::ParentingYouth
  class ActiveClients < GrdaWarehouse::WarehouseReports::Dashboard::Active

    def history_scope(scope)
      scope.parenting_youth
    end
  end
end