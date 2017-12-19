module GrdaWarehouse::WarehouseReports::Dashboard::ParentingYouth
  class ActiveClients < GrdaWarehouse::WarehouseReports::Dashboard::Active

    def client_source
      GrdaWarehouse::Hud::Client.destination.
        parenting_youth(start_date: @range.start, end_date: @range.end)
    end


  end
end