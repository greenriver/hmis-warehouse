class AdjustmentsToPatientReferrals < ActiveRecord::Migration
  def change
    add_column :patient_referrals, :accountable_care_organization_id, :integer
    add_column :patient_referrals, :effective_date, :datetime
  end
end
