module GrdaWarehouse::WarehouseReports::Dashboard::IndividualAdult
  class EnteredClients < GrdaWarehouse::WarehouseReports::Dashboard::Entered

    def client_source
      GrdaWarehouse::Hud::Client.destination.
        individual_adult(start_date: @start_date, end_date: @end_date)
    end

    def history_scope(scope)
      scope.individual_adult
    end

  end
end