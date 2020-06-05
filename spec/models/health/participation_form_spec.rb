require 'rails_helper'

RSpec.describe Health::ParticipationForm, type: :model do
  let(:patient) { create :patient, client_id: 999 }
  let(:prior_referral) { create :prior_referral }
  let(:contributing_referral) { create :contributing_referral }
  let(:current_referral) { create :current_referral }
  let(:signed_participation_form) { create :signed_participation_form }

  it 'is included in the enrollments when signed after the enrollment date' do
    signed_participation_form.update(patient_id: patient.id)
    expect(patient.participation_forms.during_current_enrollment.exists?).to be true
    expect(patient.participation_forms.during_contributing_enrollments.exists?).to be true
  end

  it 'not included in the enrollments when signed after non-contributing enrollment date, before contributing enrollment date' do
    patient.patient_referrals = [prior_referral, current_referral]
    signed_participation_form.update(patient_id: patient.id, signature_on: prior_referral.enrollment_start_date + 1.day)
    expect(patient.participation_forms.during_current_enrollment.exists?).to be false
    expect(patient.participation_forms.during_contributing_enrollments.exists?).to be false
  end

  it 'is included only in the contributed enrollments when signed after contributing enrollment date, before current enrollment date' do
    patient.patient_referrals = [prior_referral, contributing_referral, current_referral]
    signed_participation_form.update(patient_id: patient.id, signature_on: contributing_referral.enrollment_start_date + 1.day)
    expect(patient.participation_forms.during_current_enrollment.exists?).to be false
    expect(patient.participation_forms.during_contributing_enrollments.exists?).to be true
  end

  it 'is not expired if signed in the last year' do
    signed_participation_form.update(patient_id: patient.id, signature_on: Date.current - 6.months)
    expect(patient.participation_forms.expired.exists?).to be false
  end

  it 'is expired if signed in the more than a year ago' do
    signed_participation_form.update(patient_id: patient.id, signature_on: Date.current - 13.months)
    expect(patient.participation_forms.expired.exists?).to be true
  end
end
