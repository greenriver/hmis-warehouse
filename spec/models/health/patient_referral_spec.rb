require 'rails_helper'

RSpec.describe Health::PatientReferral, type: :model do
  describe 'derive referrals' do
    it 'leaves simple open referrals alone' do
      open_referral = create :patient_referral
      expect(Health::PatientReferral.count).to eq(1)

      open_referral.build_derived_referrals.map(&:save!)
      expect(Health::PatientReferral.count).to eq(1)
    end

    it 'leaves simple closed referrals alone' do
      closed_referral = create :patient_referral, enrollment_start_date: Date.current - 91.days
      closed_referral.update(disenrollment_date: Date.current)
      expect(closed_referral.versions.count).to eq(2)
      expect(Health::PatientReferral.count).to eq(1)

      closed_referral.build_derived_referrals.map(&:save!)
      expect(Health::PatientReferral.count).to eq(1)
    end

    it 'creates two contributing referrals  (one current) for re-opened referrals in 90 days' do
      closed_referral = create :patient_referral, enrollment_start_date: Date.current - 91.days
      closed_referral.update(disenrollment_date: Date.current - 31.days)
      closed_referral.update(disenrollment_date: nil)
      closed_referral.update(enrollment_start_date: Date.current)
      expect(closed_referral.versions.count).to eq(4)
      expect(Health::PatientReferral.count).to eq(1)

      closed_referral.build_derived_referrals.map(&:save!)
      expect(Health::PatientReferral.count).to eq(2)
      expect(Health::PatientReferral.contributing.count).to eq(2)
      expect(Health::PatientReferral.current.count).to eq(1)
    end

    it 'creates two separate referrals (one current), for re-opened referrals in 90 days' do
      closed_referral = create :patient_referral, enrollment_start_date: Date.current - 101.days
      closed_referral.update(disenrollment_date: Date.current - 91.days)
      closed_referral.update(disenrollment_date: nil)
      closed_referral.update(enrollment_start_date: Date.current)
      expect(closed_referral.versions.count).to eq(4)
      expect(Health::PatientReferral.count).to eq(1)

      closed_referral.build_derived_referrals.map(&:save!)
      expect(Health::PatientReferral.count).to eq(2)
      expect(Health::PatientReferral.contributing.count).to eq(1)
      expect(Health::PatientReferral.current.count).to eq(1)
    end
  end

  describe 'clean up referrals' do
    let!(:health_data_source) { create :health_data_source }
    let!(:referral_ds) { create :referral_ds }
    let(:referral) do
      {
        first_name: 'Test',
        last_name: 'Referral',
        birthdate: Date.current,
        medicaid_id: '123456',
        enrollment_start_date: Date.current,
      }
    end

    it 'closes unclosed prior referrals' do
      prior_referral = Health::PatientReferral.create_referral(nil, referral)
      current_referral = Health::PatientReferral.create_referral(prior_referral.patient, referral.merge(enrollment_start_date: Date.tomorrow))
      prior_referral.update(disenrollment_date: nil)

      Health::PatientReferral.cleanup_referrals
      expect(current_referral.patient.patient_referrals.count).to eq(2)
      expect(prior_referral.reload.disenrollment_date).not_to be_nil
    end

    it 'removes empty_referrals' do
      prior_referral = Health::PatientReferral.create_referral(nil, referral)
      current_referral = Health::PatientReferral.create_referral(prior_referral.patient, referral)

      Health::PatientReferral.cleanup_referrals
      expect(current_referral.patient.patient_referrals.count).to eq(1)
    end

    it 'combines duplicate starts, making one current if there isn\'t none' do
      r1 = Health::PatientReferral.create_referral(nil, referral)
      r2 = Health::PatientReferral.create_referral(r1.patient, referral)
      r3 = Health::PatientReferral.create_referral(r1.patient, referral)
      r1.update(disenrollment_date: Date.tomorrow)
      r2.update(disenrollment_date: Date.tomorrow)
      r3.update(disenrollment_date: Date.tomorrow, current: false)

      r1.reload
      expect(r1.patient.patient_referrals.count).to eq(3)
      expect(r1.patient.patient_referral).to be_nil

      Health::PatientReferral.cleanup_referrals

      r1.reload
      expect(r1.patient.patient_referrals.count).to eq(1)
      expect(r1.patient.patient_referral).not_to be_nil
    end

    it 'combines duplicate starts, keeping the current if there is one' do
      r1 = Health::PatientReferral.create_referral(nil, referral)
      r2 = Health::PatientReferral.create_referral(r1.patient, referral)
      r3 = Health::PatientReferral.create_referral(r1.patient, referral)
      r1.update(disenrollment_date: Date.tomorrow)
      r2.update(disenrollment_date: Date.tomorrow)
      r3.update(disenrollment_date: Date.tomorrow)

      r1.reload
      expect(r1.patient.patient_referral.id).to eq(r3.id)
      expect(r1.patient.patient_referrals.count).to eq(3)

      Health::PatientReferral.cleanup_referrals

      r1.reload
      expect(r1.patient.patient_referrals.count).to eq(1)
      expect(r1.patient.patient_referral.id).to eq(r3.id)
    end
  end
end
