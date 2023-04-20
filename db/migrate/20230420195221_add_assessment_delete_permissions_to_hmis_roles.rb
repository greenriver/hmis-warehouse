class AddAssessmentDeletePermissionsToHmisRoles < ActiveRecord::Migration[6.1]
  def change
    add_column :hmis_roles, :can_delete_assessments, :boolean, null: false, default: false
  end
end
