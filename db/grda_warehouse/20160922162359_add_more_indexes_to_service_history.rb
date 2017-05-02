class AddMoreIndexesToServiceHistory < ActiveRecord::Migration
  def change
    add_index :warehouse_client_service_history, [:date, :data_source_id, :organization_id, :project_id], name: :index_sh_date_ds_id_org_id_proj_id
  end
end
