class UpdateProcessedLastSeenFormat < ActiveRecord::Migration[5.2]
  def up
    client_ids = GrdaWarehouse::WarehouseClientsProcessed.where.not(last_homeless_visit: nil).pluck(:client_id)
    GrdaWarehouse::WarehouseClientsProcessed.update_cached_counts(client_ids: client_ids)
  end
end
