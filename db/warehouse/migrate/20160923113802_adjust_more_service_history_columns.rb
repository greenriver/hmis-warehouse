class AdjustMoreServiceHistoryColumns < ActiveRecord::Migration
  def change
    remove_index :warehouse_client_service_history, name: :index_warehouse_client_service_history_on_date
    remove_index :warehouse_client_service_history, name: :service_history_date_desc
    remove_index :warehouse_client_service_history, name: :index_sh_date_ds_id_org_id_proj_id
    remove_index :warehouse_client_service_history, name: :index_warehouse_client_service_history_on_household_id
    remove_index :warehouse_client_service_history, name: :index_warehouse_client_service_history_on_project_type
    remove_index :warehouse_client_service_history, name: :index_warehouse_client_service_history_on_record_type

    change_column :warehouse_client_service_history, :household_id, :string, limit: 50
    change_column :warehouse_client_service_history, :project_id, :string, limit: 50
    change_column :warehouse_client_service_history, :project_name, :string, limit: 150
    change_column :warehouse_client_service_history, :organization_id, :string, limit: 50
    change_column :warehouse_client_service_history, :record_type, :string, limit: 50

    add_index :warehouse_client_service_history, [:date, :data_source_id, :organization_id, :project_id, :project_type], name: :sh_date_ds_id_org_id_proj_id_proj_type
    add_index :warehouse_client_service_history, :household_id
    add_index :warehouse_client_service_history, :project_type
    add_index :warehouse_client_service_history, :record_type
  end
end
