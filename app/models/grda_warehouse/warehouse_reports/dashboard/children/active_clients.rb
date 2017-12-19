module GrdaWarehouse::WarehouseReports::Dashboard::Children
  class ActiveClients < GrdaWarehouse::WarehouseReports::Dashboard::Active

    def client_source
      GrdaWarehouse::Hud::Client.destination.
        children_only(start_date: @range.start, end_date: @range.end)
    end


  end
end