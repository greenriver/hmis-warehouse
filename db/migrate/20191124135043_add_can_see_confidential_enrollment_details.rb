class AddCanSeeConfidentialEnrollmentDetails < ActiveRecord::Migration
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
  end

  def down
    remove_column :roles, :can_view_confidential_enrollment_details
  end
end
