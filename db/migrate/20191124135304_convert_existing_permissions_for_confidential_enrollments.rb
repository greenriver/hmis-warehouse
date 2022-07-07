class ConvertExistingPermissionsForConfidentialEnrollments < ActiveRecord::Migration[4.2]
  def up
    Role.where(can_view_projects: true, can_view_clients: true).update_all(can_view_confidential_project_names: true)
  end
end
