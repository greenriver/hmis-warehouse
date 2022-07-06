class AddCanSeeConfidentialEnrollmentDetails < ActiveRecord::Migration[4.2]
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
  end

  def down
    remove_column :roles, :can_view_confidential_project_names
  end
end
