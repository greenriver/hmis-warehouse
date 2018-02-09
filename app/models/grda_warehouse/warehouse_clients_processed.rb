class GrdaWarehouse::WarehouseClientsProcessed < GrdaWarehouseBase
  include RandomScope

  self.table_name = :warehouse_clients_processed
  has_paper_trail
  belongs_to :client, class_name: GrdaWarehouse::Hud::Client.name
  belongs_to :warehouse_client, class_name: GrdaWarehouse::WarehouseClient.name, foreign_key: :client_id, primary_key: :destination_id
  has_many :service_history_enrollments, class_name: GrdaWarehouse::ServiceHistoryEnrollment.name, primary_key: :client_id, foreign_key: :client_id

  scope :service_history, -> {where(routine: 'service_history')}
  # scope :chronic?, -> {where chronically_homeless: true}

  # def chronic?
  #   chronically_homeless
  # end
  
  def self.update_homeless_counts client_ids: []
    most_recent_dates = GrdaWarehouse::ServiceHistoryServiceMaterialized.homeless.
      where(client_id: client_ids).
      group(:client_id).
      maximum(:date)
    first_dates = GrdaWarehouse::ServiceHistoryServiceMaterialized.homeless.
      where(client_id: client_ids).
      group(:client_id).
      minimum(:date)
    counts = GrdaWarehouse::ServiceHistoryServiceMaterialized.homeless.
      where(client_id: client_ids).
      group(:client_id).
      count(:date)
  end

  def self.update_chronic_counts client_ids: []

  end

  def self.update_total_counts client_ids: []

  end

  
end