class SetMissingTimestamps < ActiveRecord::Migration[7.0]
  def up
    # Destination Clients
    import_batch = []
    GrdaWarehouse::Hud::Client.destination.where(date_deleted: nil, date_created: nil).
      preload(:warehouse_client_destination).find_in_batches do |client_batch|
        client_batch.each do |client|
          client.date_created = client.warehouse_client_destination.min(&:created_at)
          client.date_updated ||= client.warehouse_client_destination.min(&:updated_at)
          import_batch << client

        end
        GrdaWarehouse::Hud::Client.import!(
          import_batch,
          on_duplicate_key_update: {
            conflict_target: [:id],
            columns: [:DateUpdated, :DateCreated],
          },
        )
      end

    # Source Clients
    import_batch = []
    GrdaWarehouse::Hud::Client.source.where(date_deleted: nil, date_created: nil).
      preload(:warehouse_client_source).find_in_batches do |client_batch|
        client_batch.each do |client|
          client.date_created = client.warehouse_client_source.created_at
          client.date_updated ||= client.warehouse_client_source.updated_at
          import_batch << client

        end
        GrdaWarehouse::Hud::Client.import!(
          import_batch,
          on_duplicate_key_update: {
            conflict_target: [:id],
            columns: [:DateUpdated, :DateCreated],
          },
        )
      end
  end
end
