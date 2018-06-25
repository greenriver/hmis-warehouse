class AddPatientIdToPatientReferral < ActiveRecord::Migration
  def change
    add_reference :patient_referrals, :patient
  end
end
