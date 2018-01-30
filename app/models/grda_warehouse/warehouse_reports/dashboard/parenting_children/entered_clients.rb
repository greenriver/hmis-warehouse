module GrdaWarehouse::WarehouseReports::Dashboard::ParentingChildren
  class EnteredClients < GrdaWarehouse::WarehouseReports::Dashboard::Entered

    def history_scope(scope)
      scope.parenting_juvenile
    end
  end
end