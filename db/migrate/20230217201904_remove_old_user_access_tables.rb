class RemoveOldUserAccessTables < ActiveRecord::Migration[6.1]
  def change
    drop_table :user_hmis_data_source_roles
    drop_table :hmis_access_group_members

    remove_column :hmis_access_groups, :scope, :string
  end
end
