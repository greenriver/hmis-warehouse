class AddDisenrollmentDateToPatientReferrals < ActiveRecord::Migration
  def change
    add_column :patient_referrals, :disenrollment_date, :date
    add_column :patient_referrals, :stop_reason_description, :string
  end
end
