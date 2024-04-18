class AddClientNamePermission < ActiveRecord::Migration[6.1]
  def up
    ::Hmis::Role.ensure_permissions_exist
    ::Hmis::Role.reset_column_information

    ::Hmis::Role.where(can_view_clients: true).update_all(can_view_client_name: true)
  end

  def down
    remove_column :hmis_roles, :can_view_client_name
  end
end
