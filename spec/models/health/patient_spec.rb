require 'rails_helper'
require 'faker'

RSpec.describe Health::Patient, type: :model do
  describe 'uniqueness constraints' do
    let(:patient_01) { build :patient, client_id: 999 }
    let(:patient_02) { build :patient, client_id: 999 }
    let(:patient_03) { build :patient, client_id: 999, deleted_at: Time.now }

    it 'forbid two patients with same client id' do
      patient_01.save!
      expect { patient_02.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'allow two patients with the same client id, if one is soft deleted' do
      patient_03.save!
      patient_01.save!

      expect(Health::Patient.all).to include patient_01
    end

    it 'allow two patients with the same client id, if one is soft deleted, but not adding a third' do
      patient_03.save!
      patient_01.save!

      expect { patient_02.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe 'enrollment scenarios' do
    let!(:data_source) { create :health_data_source }
    let!(:referral_ds) { create :referral_ds }

    before(:each) do
      Timecop.travel(Date.current - 2.years) # Enrollment durations depend on time if there is no disenrollment date
      referral_args = {
        first_name: 'First',
        last_name: 'Last',
        birthdate: Date.current,
        medicaid_id: Faker::Number.number(digits: 10),
        enrollment_start_date: Date.current,
      }
      @referral = Health::PatientReferral.create_referral(nil, referral_args)
      @referral.convert_to_patient
      @patient = @referral.patient
    end

    after(:each) do
      Timecop.return
    end

    it 'sets the default outreach cut-off and engagement dates after referral' do
      enrollment_start_date = @referral.enrollment_start_date

      aggregate_failures do
        expect(@patient.outreach_cutoff_date).to eq(enrollment_start_date + 90.days)
        expect(@patient.engagement_date).to eq(enrollment_start_date + 150.days)
      end
    end

    it 'adjusts the outreach cut-off and engagement dates after auto re-enrollment' do
      enrollment_start_date = @referral.enrollment_start_date
      @patient.patient_referral.update(disenrollment_date: enrollment_start_date + 60.days)
      re_enrollment_date = enrollment_start_date + 90.days
      referral_args = {
        first_name: @referral.first_name,
        last_name: @referral.last_name,
        birthdate: @referral.birthdate,
        medicaid_id: @referral.medicaid_id,
        enrollment_start_date: re_enrollment_date,
      }
      Health::PatientReferral.create_referral(@patient, referral_args)
      @patient.reload

      expect(@patient.patient_referrals.count).to eq(2)
      aggregate_failures do
        # Days disenrolled days don't count against outreach for auto re-enrollment
        expect(@patient.outreach_cutoff_date).to eq(enrollment_start_date + 30.days + 90.days)
        expect(@patient.engagement_date).to eq(re_enrollment_date + 150.days)
      end
    end

    it 'does not adjust the engagement date after auto re-enrollment if there is a valid care plan' do
      enrollment_start_date = @referral.enrollment_start_date
      create :careplan, patient: @patient, provider_signed_on: enrollment_start_date + 30.days, patient_signed_on: enrollment_start_date + 30.days
      @patient.patient_referral.update(disenrollment_date: enrollment_start_date + 60.days)
      re_enrollment_date = enrollment_start_date + 90.days
      referral_args = {
        first_name: @referral.first_name,
        last_name: @referral.last_name,
        birthdate: @referral.birthdate,
        medicaid_id: @referral.medicaid_id,
        enrollment_start_date: re_enrollment_date,
      }
      Health::PatientReferral.create_referral(@patient, referral_args)
      @patient.reload

      expect(@patient.patient_referrals.count).to eq(2)
      aggregate_failures do
        # Days disenrolled days don't count against outreach for auto re-enrollment
        expect(@patient.outreach_cutoff_date).to eq(enrollment_start_date + 30.days + 90.days)
        expect(@patient.engagement_date).to eq(enrollment_start_date + 150.days)
      end
    end

    it 'it resets the outreach and engagement dates for a re-enrollment after expiration' do
      enrollment_start_date = @referral.enrollment_start_date
      careplan = create :careplan, patient: @patient, provider_signed_on: enrollment_start_date + 30.days, patient_signed_on: enrollment_start_date + 30.days
      @patient.patient_referral.update(disenrollment_date: enrollment_start_date + 60.days)
      new_enrollment_date = careplan.expires_on + 1.day
      Timecop.travel(new_enrollment_date)
      referral_args = {
        first_name: @referral.first_name,
        last_name: @referral.last_name,
        birthdate: @referral.birthdate,
        medicaid_id: @referral.medicaid_id,
        enrollment_start_date: new_enrollment_date,
      }
      Health::PatientReferral.create_referral(@patient, referral_args)
      @patient.reload

      expect(@patient.patient_referrals.count).to eq(2)
      aggregate_failures do
        expect(@patient.outreach_cutoff_date).to eq(new_enrollment_date + 90.days)
        expect(@patient.engagement_date).to eq(new_enrollment_date + 150.days)
      end
    end
  end
end
