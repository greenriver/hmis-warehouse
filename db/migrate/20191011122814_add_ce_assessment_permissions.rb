class AddCeAssessmentPermissions < ActiveRecord::Migration
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
  end

  def down
    remove_column :roles, :can_view_ce_assessment
    remove_column :roles, :can_edit_ce_assessment
    remove_column :roles, :can_submit_ce_assessment
  end
end
