class AddAdHocDataSourcePermission < ActiveRecord::Migration
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
  end

  def down
    remove_column :roles, :can_manage_ad_hoc_data_sources
    remove_column :roles, :can_view_client_ad_hoc_data_sources
  end
end
