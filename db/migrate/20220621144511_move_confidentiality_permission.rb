class MoveConfidentialityPermission < ActiveRecord::Migration[6.1]
  def change
    Role.where(can_view_confidential_enrollment_details: true).update_all(can_view_confidential_project_names: true)
    remove_column :roles, :can_view_confidential_enrollment_details, :boolean, default: false, null: false
  end
end
