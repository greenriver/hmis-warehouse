module GrdaWarehouse
  class RecentServiceHistory < GrdaWarehouseBase
    self.table_name = :recent_service_history

    # NOTE: This is backed by a materialized view that will not be dumped with
    # warehouse:db:schema:dump, nor loaded with warehouse:db:schema:load
    # it will only be created with warehouse:db:migrate

    def readonly?
      true
    end

    def self.refresh_view
      connection = GrdaWarehouseBase.connection
      connection.execute('REFRESH MATERIALIZED VIEW recent_service_history;')
    end
  end
end