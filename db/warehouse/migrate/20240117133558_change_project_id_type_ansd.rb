class ChangeProjectIdTypeAnsd < ActiveRecord::Migration[6.1]
  def up
    # Blow away all ansd_enrollments, and AllNeighborsSystemDashboard::Report
    safety_assured do
      AllNeighborsSystemDashboard::Report.delete_all
      AllNeighborsSystemDashboard::Enrollment.delete_all

      remove_column :ansd_enrollments, :project_id, :string
      add_column :ansd_enrollments, :project_id, :bigint
    end
  end
end
