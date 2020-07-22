module GrdaWarehouse::EtoQaaws
  class ClientLookup < GrdaWarehouseBase
    self.table_name = :eto_client_lookups
    belongs_to :data_source, class_name: 'GrdaWarehouse::DataSource'
    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
    has_one :destination_client, through: :client

  end
end