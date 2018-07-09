class AddTimestampsToAgencyPatientReferrals < ActiveRecord::Migration
  def change
    add_timestamps :agency_patient_referrals
  end
end
