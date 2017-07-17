class IndexComputedProjectTypes < ActiveRecord::Migration
  def change
    add_index :Project, :computed_project_type
    add_index :warehouse_client_service_history, :computed_project_type
  end
end
