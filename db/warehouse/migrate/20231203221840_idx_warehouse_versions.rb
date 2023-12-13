class IdxWarehouseVersions < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    # indexes for audit reports
    add_index :versions, :client_id, algorithm: :concurrently
    add_index :versions, :enrollment_id, algorithm: :concurrently
    add_index :versions, :project_id, algorithm: :concurrently
  end
end
