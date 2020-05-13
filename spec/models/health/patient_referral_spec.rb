require 'rails_helper'

RSpec.describe Health::PatientReferral, type: :model do
  describe 'derive referrals' do
    it 'leaves simple open referrals alone' do
      open_referral = create :patient_referral
      expect(Health::PatientReferral.count).to eq(1)

      Health::PatientReferral.build_derived_referrals(open_referral.compute_enrollment_changes).map(&:save!)
      expect(Health::PatientReferral.count).to eq(1)
    end

    it 'leaves simple closed referrals alone' do
      Timecop.freeze(Date.current - 91.days) do
        closed_referral = create :patient_referral
        Timecop.travel(Date.current + 91.days)
        closed_referral.update(disenrollment_date: Date.current)
        expect(closed_referral.versions.count).to eq(2)
        expect(Health::PatientReferral.count).to eq(1)

        Health::PatientReferral.build_derived_referrals(closed_referral.compute_enrollment_changes).map(&:save!)
        expect(Health::PatientReferral.count).to eq(1)
      end
    end

    it 'creates two contributing referrals  (one current) for re-opened referrals in 90 days' do
      Timecop.freeze(Date.current - 91.days) do
        closed_referral = create :patient_referral
        Timecop.travel(Date.current + 60.days)
        closed_referral.update(disenrollment_date: Date.current)
        Timecop.travel(Date.current + 31.days)
        closed_referral.update(disenrollment_date: nil)
        expect(closed_referral.versions.count).to eq(3)
        expect(Health::PatientReferral.count).to eq(1)

        Health::PatientReferral.build_derived_referrals(closed_referral.compute_enrollment_changes).map(&:save!)
        expect(Health::PatientReferral.count).to eq(2)
        expect(Health::PatientReferral.contributing.count).to eq(2)
        expect(Health::PatientReferral.current.count).to eq(1)
      end
    end

    it 'creates two separate referrals (one current), for re-opened referrals in 90 days' do
      Timecop.freeze(Date.current - 101.days) do
        closed_referral = create :patient_referral
        Timecop.travel(Date.current + 10.days)
        closed_referral.update(disenrollment_date: Date.current)
        Timecop.travel(Date.current + 91.days)
        closed_referral.update(disenrollment_date: nil)
        expect(closed_referral.versions.count).to eq(3)
        expect(Health::PatientReferral.count).to eq(1)

        Health::PatientReferral.build_derived_referrals(closed_referral.compute_enrollment_changes).map(&:save!)
        expect(Health::PatientReferral.count).to eq(2)
        expect(Health::PatientReferral.contributing.count).to eq(1)
        expect(Health::PatientReferral.current.count).to eq(1)
      end
    end
  end
end
