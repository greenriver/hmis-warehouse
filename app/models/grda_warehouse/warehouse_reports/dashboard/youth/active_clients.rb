module GrdaWarehouse::WarehouseReports::Dashboard::Youth
  class ActiveClients < GrdaWarehouse::WarehouseReports::Dashboard::Active

    def history_scope(scope)
      scope.unaccompanied_youth
    end

  end
end