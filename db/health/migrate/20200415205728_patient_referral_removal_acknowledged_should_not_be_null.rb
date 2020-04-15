class PatientReferralRemovalAcknowledgedShouldNotBeNull < ActiveRecord::Migration[5.2]
  def change
    change_column_null :patient_referrals, :removal_acknowledged, false, false
  end
end
