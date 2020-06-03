require 'rails_helper'

RSpec.describe Health::ComprehensiveHealthAssessment, type: :model do
  let(:client) { create :fixed_destination_client }
  let(:patient) { create :patient, client: client }
  let(:prior_referral) { create :prior_referral }
  let(:contributing_referral) { create :contributing_referral }
  let(:current_referral) { create :current_referral }
  let(:cha) { create :cha, patient: patient }
  let(:cha_incomplete) { create :cha_incomplete, patient: patient }

  it 'is not included in the enrollments when not completed' do
    cha_incomplete.update(patient_id: patient.id)
    expect(patient.comprehensive_health_assessments.during_current_enrollment.exists?).to be false
    expect(patient.comprehensive_health_assessments.during_contributing_enrollments.exists?).to be false
  end

  it 'is included in the enrollments when signed after the enrollment date' do
    cha.update(patient_id: patient.id)
    expect(patient.comprehensive_health_assessments.during_current_enrollment.exists?).to be true
    expect(patient.comprehensive_health_assessments.during_contributing_enrollments.exists?).to be true
  end

  it 'not included in the enrollments when signed after non-contributing enrollment date, before contributing enrollment date' do
    patient.patient_referrals = [prior_referral, current_referral]
    cha.update(patient_id: patient.id, completed_at: prior_referral.enrollment_start_date + 1.day)
    expect(patient.comprehensive_health_assessments.during_current_enrollment.exists?).to be false
    expect(patient.comprehensive_health_assessments.during_contributing_enrollments.exists?).to be false
  end

  it 'is included onl in the contributed enrollments when signed after contributing enrollment date, before current enrollment date' do
    patient.patient_referrals = [prior_referral, contributing_referral, current_referral]
    cha.update(patient_id: patient.id, completed_at: contributing_referral.enrollment_start_date + 1.day)
    expect(patient.comprehensive_health_assessments.during_current_enrollment.exists?).to be false
    expect(patient.comprehensive_health_assessments.during_contributing_enrollments.exists?).to be true
  end

  it 'is not expired if signed in the last year' do
    cha.update(patient_id: patient.id, completed_at: Date.current - 6.months)
    expect(patient.comprehensive_health_assessments.expired.exists?).to be false
  end

  it 'is expired if signed in the more than a year ago' do
    cha.update(patient_id: patient.id, completed_at: Date.current - 13.months)
    expect(patient.comprehensive_health_assessments.expired.exists?).to be true
  end
end
