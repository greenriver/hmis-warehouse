class RenameCanViewConfidentialEnrollmentDetails < ActiveRecord::Migration[6.1]
  def change
    rename_column :roles, :can_view_confidential_project_names, :can_view_confidential_project_names
  end
end
