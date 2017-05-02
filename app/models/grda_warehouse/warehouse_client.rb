class GrdaWarehouse::WarehouseClient < GrdaWarehouseBase
  has_paper_trail

  belongs_to :destination, class_name: 'GrdaWarehouse::Hud::Client',
    inverse_of: :warehouse_client_destination
  belongs_to :source, class_name: 'GrdaWarehouse::Hud::Client',
    inverse_of: :warehouse_client_source

  belongs_to :data_source
  belongs_to :client_match
end