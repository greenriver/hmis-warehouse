class AdjustColumnLengthOnServiceHistory < ActiveRecord::Migration
  def change
    change_column :warehouse_client_service_history, :enrollment_group_id, :string, limit: 50
    change_column :warehouse_client_service_history, :head_of_household_id, :string, limit: 50
    # change_column :warehouse_client_service_history, :household_id, :string, limit: 50
    # change_column :warehouse_client_service_history, :project_id, :string, limit: 50
    # change_column :warehouse_client_service_history, :project_name, :string, limit: 150
    # change_column :warehouse_client_service_history, :organization_id, :string, limit: 50
    # change_column :warehouse_client_service_history, :record_type, :string, limit: 50
  end
end
