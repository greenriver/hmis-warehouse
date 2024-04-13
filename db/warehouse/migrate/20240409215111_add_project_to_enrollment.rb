class AddProjectToEnrollment < ActiveRecord::Migration[6.1]
  def up
    safety_assured do
      add_column :Enrollment, :project_pk, :bigint, index: true
      add_foreign_key :Enrollment, :Project, column: :project_pk, name: 'fk_rails_enrollment_project_pk'
    end
  end

  def down
    remove_column :Enrollment, :project_pk
  end
end
