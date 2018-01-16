module GrdaWarehouse::WarehouseReports::Dashboard::IndividualAdult
  class ActiveClients < GrdaWarehouse::WarehouseReports::Dashboard::Active

    def client_source
      GrdaWarehouse::Hud::Client.destination.
        individual_adult(start_date: @range.start, end_date: @range.end)
    end

    def homeless_service_history_source
      service_history_source.
        homeless.
        individual_adult
    end

  end
end