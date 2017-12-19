module GrdaWarehouse::WarehouseReports::Dashboard::Families
  class HousedClients < GrdaWarehouse::WarehouseReports::Dashboard::Housed

    def client_source
      GrdaWarehouse::Hud::Client.destination.family(start_date: @start_date, end_date: @end_date)
    end

    def exits_from_homelessness
      service_history_source.exit.
        joins(:client).
        homeless.
        family.
        open_between(start_date: @start_date, end_date: @end_date)
    end


  end
end