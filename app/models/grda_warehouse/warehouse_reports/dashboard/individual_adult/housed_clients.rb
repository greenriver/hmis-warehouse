module GrdaWarehouse::WarehouseReports::Dashboard::IndividualAdult
  class HousedClients < GrdaWarehouse::WarehouseReports::Dashboard::Housed

    def client_source
      GrdaWarehouse::Hud::Client.destination.
        individual_adult(start_date: @start_date, end_date: @end_date)
    end

    def exits_from_homelessness
      service_history_source.exit.
        joins(:client).
        homeless.
        individual_adult.
        open_between(start_date: @start_date, end_date: @end_date)
    end

  end
end