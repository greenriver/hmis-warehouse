class AddPatientIdToPatientReferral < ActiveRecord::Migration[4.2]
  def change
    add_reference :patient_referrals, :patient
  end
end
