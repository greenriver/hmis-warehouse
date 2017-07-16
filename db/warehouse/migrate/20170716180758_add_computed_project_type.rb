class AddComputedProjectType < ActiveRecord::Migration
  def change
    add_column :Project, :computed_project_type, :integer
    add_column :warehouse_client_service_history, :computed_project_type, :integer
  end
end
