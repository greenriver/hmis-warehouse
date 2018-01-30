module GrdaWarehouse::WarehouseReports::Dashboard::Veteran
  class ActiveClients < GrdaWarehouse::WarehouseReports::Dashboard::Active

    def history_scope(scope)
      scope.veteran
    end
  end
end