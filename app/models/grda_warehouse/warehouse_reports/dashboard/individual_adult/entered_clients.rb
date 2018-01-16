module GrdaWarehouse::WarehouseReports::Dashboard::IndividualAdult
  class EnteredClients < GrdaWarehouse::WarehouseReports::Dashboard::Entered

    def history_scope(scope)
      scope.individual_adult
    end

  end
end