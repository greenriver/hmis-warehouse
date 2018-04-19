class AddCanAddAdministrativeEvents < ActiveRecord::Migration
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
  end
  def down
    remove_column :roles, :can_add_administrative_event, :boolean, default: false
  end
end
