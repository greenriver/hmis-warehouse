class CreateServiceHistoryServicesMaterialized < ActiveRecord::Migration
  def up
    sql = GrdaWarehouse::ServiceHistoryServiceMaterialized.view_sql
    execute(sql)
    add_index :service_history_services_materialized, :id, unique: true 
    add_index :service_history_services_materialized, [:client_id, :project_type, :record_type], name: :index_shsm_c_id_p_type_r_type
    add_index :service_history_services_materialized, [:project_type, :record_type], name: :index_shsm_p_type_r_type
  end

  def down
    sql = GrdaWarehouse::ServiceHistoryServiceMaterialized.remove_view_sql
    execute(sql)
  end
end
