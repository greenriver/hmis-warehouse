module GrdaWarehouse::WarehouseReports::Dashboard::NonVeteran
  class ActiveClients < GrdaWarehouse::WarehouseReports::Dashboard::Active

    def history_scope(scope)
      scope.non_veteran
    end

  end
end