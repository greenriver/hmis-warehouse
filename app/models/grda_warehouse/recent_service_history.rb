module GrdaWarehouse
  class RecentServiceHistory < GrdaWarehouseBase
    self.table_name = :recent_service_history

    def readonly?
      true
    end

  end
end