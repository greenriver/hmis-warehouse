class MoveCasToCaAssessments < ActiveRecord::Migration[6.1]
  def change
    chas = []
    # The CHA model refers to the translations at load time (through constants), so we bypass it here
    HealthBase.connection.execute("SELECT id, patient_id FROM comprehensive_health_assessments WHERE deleted_at IS NULL").each do |cha|
      cha_id = cha['id']
      patient_id = cha['patient_id']
      chas << Health::CaAssessment.new(patient_id: patient_id, instrument_type: 'Health::ComprehensiveHealthAssessment', instrument_id: cha_id)
    end
    Health::CaAssessment.import(chas)

    HealthComprehensiveAssessment::Assessment.find_in_batches do |batch|
      cas = []
      batch.each do |ca|
        cas << Health::HrsnScreening.new(patient_id: ca.patient_id, instrument_type: 'HealthComprehensiveAssessment::Assessment', instrument: ca)
      end
      Health::CaAssessment.import(cas)
    end
  end
end
