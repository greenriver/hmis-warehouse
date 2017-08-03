class AddGradePermission < ActiveRecord::Migration
  def up
    Role.ensure_permissions_exist
    Role.reset_column_information
    Role.where( name: %w( admin dnd_staff ) ).update_all(
      can_edit_dq_grades: true, 
    )
  end
  def down
    remove_column :roles, :can_edit_dq_grades, :boolean, default: false
  end
end
