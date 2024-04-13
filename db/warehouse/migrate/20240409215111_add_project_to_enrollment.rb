class AddProjectToEnrollment < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      add_reference :Enrollment, :actual_project, foreign_key: { to_table: :Project, name: 'fk_rails_enrollment_actual_project_di' }
    end
  end
end
