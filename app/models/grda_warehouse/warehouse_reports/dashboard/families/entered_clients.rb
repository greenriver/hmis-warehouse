module GrdaWarehouse::WarehouseReports::Dashboard::Families
  class EnteredClients < GrdaWarehouse::WarehouseReports::Dashboard::Entered

    def history_scope(scope)
      scope.family
    end
    
  end
end