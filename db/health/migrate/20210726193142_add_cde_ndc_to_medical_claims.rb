class AddCdeNdcToMedicalClaims < ActiveRecord::Migration[5.2]
  def change
    add_column :claims_reporting_medical_claims, :cde_ndc, :string, limit: 48
  end
end
