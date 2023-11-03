class AddLimitedEnrollmentPerm < ActiveRecord::Migration[6.1]
  def up
    Hmis::Role.ensure_permissions_exist
    Hmis::Role.reset_column_information
  end

  def down
    remove_column :hmis_roles, :can_view_limited_enrollment_details
  end
end
