module GrdaWarehouse::WarehouseReports::Dashboard::ParentingYouth
  class EnteredClients < GrdaWarehouse::WarehouseReports::Dashboard::Entered

    def history_scope(scope)
      scope.parenting_youth
    end

  end
end