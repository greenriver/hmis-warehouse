module GrdaWarehouse::WarehouseReports::Dashboard::NonVeteran
  class EnteredClients < GrdaWarehouse::WarehouseReports::Dashboard::Entered

    def history_scope(scope)
      scope.non_veteran
    end

  end
end