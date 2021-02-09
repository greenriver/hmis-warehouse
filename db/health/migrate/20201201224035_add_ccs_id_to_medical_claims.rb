class AddCcsIdToMedicalClaims < ActiveRecord::Migration[5.2]
  def change
    change_table 'claims_reporting_medical_claims' do |t|
      t.string :ccs_id
    end
  end
end
