module GrdaWarehouse::WarehouseReports::Dashboard::Veteran
  class EnteredClients < GrdaWarehouse::WarehouseReports::Dashboard::Entered

    def history_scope(scope)
      scope.veteran
    end
  end
end