class GrdaWarehouse::WarehouseClientsProcessed < GrdaWarehouseBase
  include RandomScope
  include ArelHelper

  self.table_name = :warehouse_clients_processed

  belongs_to :client, class_name: GrdaWarehouse::Hud::Client.name
  belongs_to :warehouse_client, class_name: GrdaWarehouse::WarehouseClient.name, foreign_key: :client_id, primary_key: :destination_id
  has_many :service_history_enrollments, class_name: GrdaWarehouse::ServiceHistoryEnrollment.name, primary_key: :client_id, foreign_key: :client_id

  scope :service_history, -> {where(routine: 'service_history')}
  # scope :chronic?, -> {where chronically_homeless: true}

  # def chronic?
  #   chronically_homeless
  # end
  
  def self.update_cached_counts client_ids: []
    client_ids.each do |client_id|
      processed = self.where(client_id: client_id, routine: :service_history).
        first_or_initialize
      attrs = {
        last_service_updated_at: Date.today,
        first_homeless_date: first_homeless_dates(client_ids: client_ids).try(:[], client_id),
        last_homeless_date: most_recent_homeless_dates(client_ids: client_ids).try(:[], client_id),
        homeless_days: homeless_counts(client_ids: client_ids).try(:[], client_id),
        first_chronic_date: first_chronic_dates(client_ids: client_ids).try(:[], client_id),
        last_chronic_date: most_recent_chronic_dates(client_ids: client_ids).try(:[], client_id),
        chronic_days: chronic_counts(client_ids: client_ids).try(:[], client_id),
        first_date_served: first_total_dates(client_ids: client_ids).try(:[], client_id),
        last_date_served: most_recent_total_dates(client_ids: client_ids).try(:[], client_id),
        days_served: total_counts(client_ids: client_ids).try(:[], client_id), 
      }

      processed.update_attributes(attrs)
      processed.save
      GrdaWarehouse::Hud::Client.destination.clear_view_cache(client_id)
    end
  end

  def self.most_recent_homeless_dates client_ids: []
    @most_recent_homeless_dates ||= GrdaWarehouse::ServiceHistoryServiceMaterialized.homeless.
      where(client_id: client_ids).
      group(:client_id).
      maximum(:date)
  end
  def self.first_homeless_dates client_ids: []
    @first_homeless_dates ||= GrdaWarehouse::ServiceHistoryServiceMaterialized.homeless.
      where(client_id: client_ids).
      group(:client_id).
      minimum(:date)
  end
  def self.homeless_counts client_ids: []
    @homeless_counts ||= GrdaWarehouse::ServiceHistoryServiceMaterialized.homeless.
      where(client_id: client_ids).
      group(:client_id).
      distinct.
      count(:date)
  end

  def self.most_recent_chronic_dates client_ids: []
    @most_recent_chronic_dates ||= GrdaWarehouse::ServiceHistoryServiceMaterialized.homeless(chronic_types_only: true).
      where(client_id: client_ids).
      group(:client_id).
      maximum(:date)
  end
  def self.first_chronic_dates client_ids: []
    @first_chronic_dates ||= GrdaWarehouse::ServiceHistoryServiceMaterialized.homeless(chronic_types_only: true).
      where(client_id: client_ids).
      group(:client_id).
      minimum(:date)
  end
  def self.chronic_counts client_ids: []
    @chronic_counts ||= GrdaWarehouse::ServiceHistoryServiceMaterialized.homeless(chronic_types_only: true).
      where(client_id: client_ids).
      group(:client_id).
      distinct.
      count(:date)
  end

  def self.most_recent_total_dates client_ids: []
    @most_recent_total_dates ||= GrdaWarehouse::ServiceHistoryServiceMaterialized.
      where(client_id: client_ids).
      group(:client_id).
      maximum(:date)
  end
  def self.first_total_dates client_ids: []
    @first_total_dates ||= GrdaWarehouse::ServiceHistoryServiceMaterialized.
      where(client_id: client_ids).
      group(:client_id).
      minimum(:date)
  end
  def self.total_counts client_ids: []
    @total_counts ||= GrdaWarehouse::ServiceHistoryServiceMaterialized.
      where(client_id: client_ids).
      group(:client_id).
      distinct.
      count(:date)
  end  
end