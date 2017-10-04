class AddExportHmisRole < ActiveRecord::Migration
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
    Role.where( name: %w( admin ) ).update_all(
      can_export_hmis_data: true
    )
  end
  def down
    remove_column :roles, :can_export_hmis_data, :boolean, default: false
  end
end
