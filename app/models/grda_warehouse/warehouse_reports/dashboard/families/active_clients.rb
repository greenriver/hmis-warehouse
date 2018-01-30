module GrdaWarehouse::WarehouseReports::Dashboard::Families
  class ActiveClients < GrdaWarehouse::WarehouseReports::Dashboard::Active

    def history_scope(scope)
      scope.family
    end

  end
end