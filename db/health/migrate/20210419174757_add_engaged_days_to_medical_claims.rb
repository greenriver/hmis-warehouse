class AddEngagedDaysToMedicalClaims < ActiveRecord::Migration[5.2]
  def change
    add_column :claims_reporting_medical_claims, :enrolled_days, :integer, default: 0, comment: "Est. number of days the member has been enrolled as of the service start date."
    add_column :claims_reporting_medical_claims, :engaged_days, :integer, default: 0, comment: "Est. number of days the member has been engaged by a CP as of the service start date."
  end
end
