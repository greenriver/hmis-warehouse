class AddRemovalAcknowledgedToPatientReferrals < ActiveRecord::Migration[4.2]
  def change
    add_column :patient_referrals, :removal_acknowledged, :boolean, default: false
  end
end
