class RenameCanViewConfidentialEnrollmentDetails < ActiveRecord::Migration[6.1]
  def change
    add_column :roles, :can_view_confidential_project_names, :boolean, default: false, null: false
  end
end
