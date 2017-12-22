module GrdaWarehouse::WarehouseReports::Dashboard::Veteran
  class EnteredClients < GrdaWarehouse::WarehouseReports::Dashboard::Entered

    def client_source
      GrdaWarehouse::Hud::Client.destination.veteran
    end

    def history_scope(scope)
      scope.veteran
    end
  end
end