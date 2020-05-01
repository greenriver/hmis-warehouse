class AddMedicalRestrictionNotificationPermission < ActiveRecord::Migration[5.2]
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
  end

  def down
    remove_column :roles, :receives_medical_restriction_notifications
  end
end
