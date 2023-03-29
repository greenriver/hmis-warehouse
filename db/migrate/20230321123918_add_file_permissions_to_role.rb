class AddFilePermissionsToRole < ActiveRecord::Migration[6.1]
  def change
    add_column :hmis_roles, :can_manage_any_client_files, :boolean, null: false, default: false
    add_column :hmis_roles, :can_manage_own_client_files, :boolean, null: false, default: false
    add_column :hmis_roles, :can_view_any_nonconfidential_client_files, :boolean, null: false, default: false
    add_column :hmis_roles, :can_view_any_confidential_client_files, :boolean, null: false, default: false

    reversible do |dir|
      dir.up do
        Hmis::Role.where(can_manage_client_files: true).update_all(can_manage_any_client_files: true)
      end

      dir.down do
        Hmis::Role.where(can_manage_any_client_files: true).update_all(can_manage_client_files: true)
      end
    end

    remove_column :hmis_roles, :can_manage_client_files, :boolean, null: false, default: false
  end
end
