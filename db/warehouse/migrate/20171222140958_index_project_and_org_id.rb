class IndexProjectAndOrgId < ActiveRecord::Migration[4.2]
  def change
    remove_index :Project, column: :ProjectID
    add_index :Project, [:ProjectID, :data_source_id, :OrganizationID], name: :index_proj_proj_id_org_id_ds_id
  end
end
