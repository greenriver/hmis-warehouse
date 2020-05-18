class MakeExistingPatientReferralsCurrent < ActiveRecord::Migration[5.2]
  def up
    Health::PatientReferral.update_all(current: true, contributing: true)
  end
end
