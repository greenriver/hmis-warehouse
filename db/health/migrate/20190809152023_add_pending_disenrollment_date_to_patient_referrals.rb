class AddPendingDisenrollmentDateToPatientReferrals < ActiveRecord::Migration[4.2]
  def change
    add_column :patient_referrals, :pending_disenrollment_date, :date
  end
end
