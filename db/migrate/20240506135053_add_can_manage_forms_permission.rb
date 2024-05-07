class AddCanManageFormsPermission < ActiveRecord::Migration[7.0]
  def up
    ::Hmis::Role.ensure_permissions_exist
    ::Hmis::Role.reset_column_information

    ::Hmis::Role.where(can_configure_data_collection: true).update_all(can_manage_forms: true)
  end

  def down
    remove_column :hmis_roles, :can_manage_forms
  end
end
