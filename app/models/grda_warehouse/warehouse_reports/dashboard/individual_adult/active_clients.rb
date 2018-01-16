module GrdaWarehouse::WarehouseReports::Dashboard::IndividualAdult
  class ActiveClients < GrdaWarehouse::WarehouseReports::Dashboard::Active

    def history_scope(scope)
      scope.individual_adult
    end

  end
end