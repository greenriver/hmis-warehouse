class AddAnnualAssessmentToDqtEnrollments < ActiveRecord::Migration[6.1]
  def change
    change_table :hmis_dqt_enrollments do |t|
      t.boolean :annual_expected
      t.date :enrollment_anniversary_date
      t.json :annual_assessment_status
    end
  end
end
