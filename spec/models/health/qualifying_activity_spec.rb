require 'rails_helper'
require 'faker'

RSpec.describe Health::QualifyingActivity, type: :model do
  describe 'with single referral' do
    let(:pre_enrollment_activity) { create :qualifying_activity, :old_qa }
    let(:qualifying_activity) { create :qualifying_activity }

    it 'partitions QAs by date' do
      pre_enrollment_activity.calculate_payability!
      qualifying_activity.calculate_payability!

      expect(pre_enrollment_activity.naturally_payable).to be false
      expect(qualifying_activity.naturally_payable).to be true
    end
  end

  describe 'with multiple referrals' do
    let(:pre_enrollment_activity) { create :qualifying_activity_for_patient_a, :old_qa }
    let(:qualifying_activity) { create :qualifying_activity_for_patient_a }

    it 'partitions QAs by date' do
      pre_enrollment_activity.calculate_payability!
      qualifying_activity.calculate_payability!

      expect(pre_enrollment_activity.naturally_payable).to be false
      expect(qualifying_activity.naturally_payable).to be true
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

    it 'makes outreach QAs payable until the cutoff' do
      enrollment_start_date = @referral.enrollment_start_date
      payable_outreach = create :qualifying_activity, patient: @patient, activity: :outreach, date_of_activity: enrollment_start_date + 30.days
      unpayable_outreach = create :qualifying_activity, patient: @patient, activity: :outreach, date_of_activity: enrollment_start_date + 120.days

      Timecop.travel(enrollment_start_date + 240.days)
      aggregate_failures do
        expect(payable_outreach.compute_valid_unpayable?).to be false
        expect(unpayable_outreach.compute_valid_unpayable?).to be true
      end
    end

    it 'makes non-outreach QAs payable until the engagement date' do
      enrollment_start_date = @referral.enrollment_start_date
      payable_qa = create :qualifying_activity, patient: @patient, activity: :community_connection, date_of_activity: enrollment_start_date + 120.days
      unpayable_qa = create :qualifying_activity, patient: @patient, activity: :community_connection, date_of_activity: enrollment_start_date + 180.days

      Timecop.travel(enrollment_start_date + 240.days)
      aggregate_failures do
        expect(payable_qa.compute_valid_unpayable?).to be false
        expect(unpayable_qa.compute_valid_unpayable?).to be true
      end
    end

    it 'keeps non-outreach QAs payable after the engagement date with a signed care plan' do
      enrollment_start_date = @referral.enrollment_start_date
      now_payable_qa = create :qualifying_activity, patient: @patient, activity: :community_connection, date_of_activity: enrollment_start_date + 180.days
      create :careplan, patient: @patient, provider_signed_on: enrollment_start_date + 30.days, patient_signed_on: enrollment_start_date + 30.days

      Timecop.travel(enrollment_start_date + 240.days)
      expect(now_payable_qa.compute_valid_unpayable?).to be false
    end

    it 'makes outreach QAs unpayable while disenrolled' do
      enrollment_start_date = @referral.enrollment_start_date
      @patient.patient_referral.update(disenrollment_date: enrollment_start_date + 59.days)
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

      payable_outreach = create :qualifying_activity, patient: @patient, activity: :outreach, date_of_activity: re_enrollment_date + 15.days
      unpayable_outreach = create :qualifying_activity, patient: @patient, activity: :outreach, date_of_activity: enrollment_start_date + 75.days

      Timecop.travel(enrollment_start_date + 240.days)
      aggregate_failures do
        expect(payable_outreach.compute_valid_unpayable?).to be false
        expect(unpayable_outreach.compute_valid_unpayable?).to be true
      end
    end

    it 'ignores non-contributing referrals' do
      enrollment_start_date = @referral.enrollment_start_date
      careplan = create :careplan, patient: @patient, provider_signed_on: enrollment_start_date + 30.days, patient_signed_on: enrollment_start_date + 30.days
      @patient.patient_referral.update(disenrollment_date: enrollment_start_date + 59.days)
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

      payable_outreach = create :qualifying_activity, patient: @patient, activity: :outreach, date_of_activity: new_enrollment_date + 60.days
      payable_qa = create :qualifying_activity, patient: @patient, activity: :community_connection, date_of_activity: enrollment_start_date + 30.days

      Timecop.travel(new_enrollment_date + 240.days)
      aggregate_failures do
        expect(payable_outreach.compute_valid_unpayable?).to be false
        expect(payable_qa.compute_valid_unpayable?).to be false
      end
    end
  end
end
