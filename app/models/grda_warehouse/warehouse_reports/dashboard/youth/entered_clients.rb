module GrdaWarehouse::WarehouseReports::Dashboard::Youth
  class EnteredClients < GrdaWarehouse::WarehouseReports::Dashboard::Entered

    def client_source
      GrdaWarehouse::Hud::Client.destination.
        unaccompanied_youth(start_date: @start_date, end_date: @end_date)
    end


  end
end