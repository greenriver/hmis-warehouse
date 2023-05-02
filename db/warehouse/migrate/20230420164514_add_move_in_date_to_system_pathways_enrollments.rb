class AddMoveInDateToSystemPathwaysEnrollments < ActiveRecord::Migration[6.1]
  def change
    add_column :system_pathways_enrollments, :move_in_date, :date
    add_column :system_pathways_enrollments, :days_to_move_in, :integer
    add_column :system_pathways_enrollments, :days_to_exit_after_move_in, :integer
  end
end
