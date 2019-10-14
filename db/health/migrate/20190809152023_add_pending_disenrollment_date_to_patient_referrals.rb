class AddPendingDisenrollmentDateToPatientReferrals < ActiveRecord::Migration
  def change
    add_column :patient_referrals, :pending_disenrollment_date, :date
  end
end
