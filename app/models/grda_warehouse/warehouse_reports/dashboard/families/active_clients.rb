module GrdaWarehouse::WarehouseReports::Dashboard::Families
  class ActiveClients < GrdaWarehouse::WarehouseReports::Dashboard::Active

    def client_source
      GrdaWarehouse::Hud::Client.destination.family(start_date: @range.start, end_date: @range.end)
    end

    def homeless_service_history_source
      service_history_source.
        homeless.
        family
    end

  end
end