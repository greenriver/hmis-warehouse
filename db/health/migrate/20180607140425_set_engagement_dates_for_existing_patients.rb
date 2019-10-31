class SetEngagementDatesForExistingPatients < ActiveRecord::Migration[4.2]
  def up
    Health::Patient.joins(:patient_referral).where(engagement_date: nil).each do |patient|
      patient.update(engagement_date: patient.patient_referral.engagement_date)
    end
  end
end
