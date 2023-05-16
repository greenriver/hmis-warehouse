class CleanUpExternalIdIndex < ActiveRecord::Migration[6.1]
  # remove redundant indexes. These columns already indexed by external_ids_uniq_source_value
  # (source_id, source_type, remote_credential_id)
  def change
    if index_exists?(:external_ids, [:source_id, :source_type, :remote_credential_id, :value], name: 'external_ids_uniq')
      remove_index :external_ids,
                  [:source_id, :source_type, :remote_credential_id, :value],
                  unique: true,
                  name: 'external_ids_uniq'
    end

    if index_exists?(:external_ids, [:source_type, :source_id], name: 'index_external_ids_on_source')
      remove_index :external_ids,
                  [:source_type, :source_id],
                  name: 'index_external_ids_on_source'
    end
  end
end
