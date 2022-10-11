class AddProjectTypeToEnrollmentTable < ActiveRecord::Migration[6.1]
  def change
    add_column :hmis_dqt_enrollments, :project_type, :integer
  end
end
