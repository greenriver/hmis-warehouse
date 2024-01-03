class IdxWarehouseVersions < ActiveRecord::Migration[6.1]
  def change
    # indexes for audit reports
    safety_assured do
      add_index :versions, :client_id
      add_index :versions, :enrollment_id
      add_index :versions, :project_id
    end
  end
end
