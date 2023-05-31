class MoveHrsnsToHrsnScreenings < ActiveRecord::Migration[6.1]
  def change
    Health::SelfSufficiencyMatrixForm.find_in_batches do |batch|
      ssms = []
      batch.each do |ssm|
        ssms << Health::HrsnScreening.new(patient_id: ssm.patient_id, instrument_type: 'Health::SelfSufficiencyMatrixForm', instrument: ssm)
      end
      Health::HrsnScreening.import(ssms)
    end

    HealthThriveAssessment::Assessment.find_in_batches do |batch|
      thrives = []
      batch.each do |thrive|
        thrives << Health::HrsnScreening.new(patient_id: thrive.patient_id, instrument_type: 'HealthThriveAssessment::Assessment', instrument: thrive)
      end
      Health::HrsnScreening.import(thrives)
    end
  end
end
