class AddTimestampsToAgencyPatientReferrals < ActiveRecord::Migration[4.2]
  def change
    add_timestamps :agency_patient_referrals
  end
end
