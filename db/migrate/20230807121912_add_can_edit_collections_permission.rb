class AddCanEditCollectionsPermission < ActiveRecord::Migration[6.1]
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
    Role.where(can_edit_access_groups: true).update_all(can_edit_collections: true)
  end

  def down
   remove_column :roles, :can_edit_collections
  end
end
