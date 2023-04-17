class AddFinalEnrollment < ActiveRecord::Migration[6.1]
  def change
    add_column :system_pathways_enrollments, :final_enrollment, :boolean, default: false, null: false
  end
end
