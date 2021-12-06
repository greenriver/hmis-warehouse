class IndexPmTables < ActiveRecord::Migration[5.2]
  def change
    add_index :pm_client_projects, [:project_id, :report_id]
    add_index :pm_client_projects, :report_id
    add_index :pm_projects, [:project_id, :report_id]
  end
end
