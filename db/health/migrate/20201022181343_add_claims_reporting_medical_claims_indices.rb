class AddClaimsReportingMedicalClaimsIndices < ActiveRecord::Migration[5.2]
  def change
    add_index :claims_reporting_medical_claims, [:member_id, :service_start_date], name: 'idx_crmc_member_service_start_date'
  end
end
