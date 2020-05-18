class AddDerivedReferralToPatientReferrals < ActiveRecord::Migration[5.2]
  def change
    add_column :patient_referrals, :derived_referral, :boolean, default: :false
  end
end
