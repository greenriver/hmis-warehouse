class AddDaysEnrolledToSpmEnrollment < ActiveRecord::Migration[6.1]
  def change
    add_column :hud_report_spm_enrollments, :days_enrolled, :integer
  end
end
