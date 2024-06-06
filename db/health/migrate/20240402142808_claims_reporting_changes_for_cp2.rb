class ClaimsReportingChangesForCp2 < ActiveRecord::Migration[6.1]
  def change
    add_column :claims_reporting_medical_claims, :pcc_repricing_fee_flag, :string, limit: 50
    add_column :claims_reporting_medical_claims, :cde_enc_rec_ind, :string, limit: 50
  end
end
