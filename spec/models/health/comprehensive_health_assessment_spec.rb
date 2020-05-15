require 'rails_helper'

RSpec.describe Health::ComprehensiveHealthAssessment, type: :model do
  let(:client) { create :fixed_destination_client }
  let(:patient) { create :patient, client: client }
  let(:prior_referral) { create :prior_referral }
  let(:contributing_referral) { create :contributing_referral }
  let(:current_referral) { create :current_referral }
  let(:cha) { create :cha, patient: patient }
  let(:cha_incomplete) { create :cha_incomplete, patient: patient }

  describe 'cha during_current_enrollment scope is' do
    it 'not included when missing updated date' do
      cha_incomplete.update(patient_id: patient.id)
      expect(Health::ComprehensiveHealthAssessment.during_current_enrollment.where(patient_id: patient.id).count).to eq(0)
    end

    it 'included when signed after the enrollment date' do
      cha.update(patient_id: patient.id)
      expect(Health::ComprehensiveHealthAssessment.during_current_enrollment.where(patient_id: patient.id).count).to eq(1)
    end

    it 'not included when signed after non-contributing enrollment date, before contributing enrollment date' do
      patient.patient_referrals = [prior_referral, current_referral]
      cha.update(patient_id: patient.id, completed_at: prior_referral.enrollment_start_date + 1.day)
      expect(Health::ComprehensiveHealthAssessment.during_current_enrollment.where(patient_id: patient.id).count).to eq(0)
    end

    it 'includes when signed after contributing enrollment date, before current enrollment date' do
      patient.patient_referrals = [prior_referral, contributing_referral, current_referral]
      cha.update(patient_id: patient.id, completed_at: contributing_referral.enrollment_start_date + 1.day)
      expect(Health::ComprehensiveHealthAssessment.during_current_enrollment.where(patient_id: patient.id).count).to eq(1)
    end
  end
end
