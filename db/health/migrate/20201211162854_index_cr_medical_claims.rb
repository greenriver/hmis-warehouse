class IndexCrMedicalClaims < ActiveRecord::Migration[5.2]
  def change
    add_index :claims_reporting_medical_claims, :aco_name
    add_index :claims_reporting_medical_claims, :aco_pidsl
  end
end
