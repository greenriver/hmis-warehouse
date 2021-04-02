class AddFirstClaimDateToEnrollments < ActiveRecord::Migration[5.2]
  def change
    add_column :claims_reporting_member_enrollment_rosters, :first_claim_date, :date, index: true
  end
end
