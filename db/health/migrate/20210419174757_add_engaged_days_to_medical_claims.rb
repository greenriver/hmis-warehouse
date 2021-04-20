class AddEngagedDaysToMedicalClaims < ActiveRecord::Migration[5.2]
  def change
    add_column :claims_reporting_medical_claims, :engaged_days, :integer, comment: "Est. number of days the member has been engaged by the CP as of the service date of this claim."
  end
end
