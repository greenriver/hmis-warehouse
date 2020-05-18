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
end
