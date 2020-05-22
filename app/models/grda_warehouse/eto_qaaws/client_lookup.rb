module GrdaWarehouse::EtoQaaws
  class ClientLookup < GrdaWarehouseBase
    self.table_name = :eto_client_lookups
    belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'

  end
end