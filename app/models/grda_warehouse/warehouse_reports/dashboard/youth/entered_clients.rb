module GrdaWarehouse::WarehouseReports::Dashboard::Youth
  class EnteredClients < GrdaWarehouse::WarehouseReports::Dashboard::Entered

    def history_scope(scope)
      scope.unaccompanied_youth
    end
  end
end