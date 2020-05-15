require 'rails_helper'

RSpec.describe Health::ParticipationForm, type: :model do
  let(:patient) { create :patient, client_id: 999 }
  let(:prior_referral) { create :prior_referral }
  let(:contributing_referral) { create :contributing_referral }
  let(:current_referral) { create :current_referral }
  let(:signed_participation_form) { create :signed_participation_form }
  let(:unsigned_participation_form) { create :unsigned_participation_form }

  describe 'participation form during_current_enrollment scope' do
    it 'includes when signed after the enrollment date' do
      signed_participation_form.update(patient_id: patient.id)
      expect(Health::ParticipationForm.during_current_enrollment.where(patient_id: patient.id).count).to eq(1)
    end

    it 'does not include when signed after non-contributing enrollment date, before contributing enrollment date' do
      patient.patient_referrals = [prior_referral, current_referral]
      signed_participation_form.update(patient_id: patient.id, signature_on: prior_referral.enrollment_start_date + 1.day)
      expect(Health::ParticipationForm.during_current_enrollment.where(patient_id: patient.id).count).to eq(0)
    end

    it 'includes when signed after contributing enrollment date, before current enrollment date' do
      patient.patient_referrals = [prior_referral, contributing_referral, current_referral]
      signed_participation_form.update(patient_id: patient.id, signature_on: contributing_referral.enrollment_start_date + 1.day)
      expect(Health::ParticipationForm.during_current_enrollment.where(patient_id: patient.id).count).to eq(1)
    end
  end
end
