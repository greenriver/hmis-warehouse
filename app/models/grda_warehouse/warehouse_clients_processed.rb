class GrdaWarehouse::WarehouseClientsProcessed < GrdaWarehouseBase
  include RandomScope

  self.table_name = :warehouse_clients_processed
  has_paper_trail
  belongs_to :client, class_name: GrdaWarehouse::Hud::Client.name

  scope :service_history, -> {where(routine: 'service_history')}
  # scope :chronic?, -> {where chronically_homeless: true}

  # def chronic?
  #   chronically_homeless
  # end
end