class AdjustmentsToPatientReferrals < ActiveRecord::Migration[4.2]
  def change
    add_column :patient_referrals, :accountable_care_organization_id, :integer
    add_column :patient_referrals, :effective_date, :datetime
  end
end
