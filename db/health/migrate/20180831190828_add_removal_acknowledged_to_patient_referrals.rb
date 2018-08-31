class AddRemovalAcknowledgedToPatientReferrals < ActiveRecord::Migration
  def change
    add_column :patient_referrals, :removal_acknowledged, :boolean, default: false
  end
end
