class AdjustExternalIdsUniqIdx < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!
  def change
    # allow more than one client MCI ID
    add_index :external_ids,
        [:source_id, :source_type, :remote_credential_id],
        unique: true,
        name: 'uidx_external_ids_source_value',
        where: "(namespace <> 'ac_hmis_mci' OR namespace IS NULL)",
        algorithm: :concurrently
    remove_index :external_ids, [:source_id, :source_type, :remote_credential_id], unique: true, name: 'external_ids_uniq_source_value', algorithm: :concurrently
  end

end
