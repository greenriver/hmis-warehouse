class AddDataSourceOrganizationProjectRecordTypeIndexToSh < ActiveRecord::Migration
  def change
    add_index :warehouse_client_service_history, [:data_source_id, :organization_id, :project_id, :record_type], name: :index_sh_ds_id_org_id_proj_id_r_type
  end
end
