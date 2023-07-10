class AddCustomServicePersonalIdIndex < ActiveRecord::Migration[6.1]
  # disable_ddl_transaction!

  def change
    # add_index :custom_imports_b_services_rows, [:personal_id, :data_source_id], name: "idx_cibs_p_id_ds_id", algorithm: :concurrently
  end
end
