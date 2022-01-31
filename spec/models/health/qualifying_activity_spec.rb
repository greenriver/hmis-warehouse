require 'rails_helper'
require 'faker'

RSpec.describe Health::QualifyingActivity, type: :model do
  describe 'with single referral' do
    let(:pre_enrollment_activity) { create :qualifying_activity, :old_qa }
    let(:qualifying_activity) { create :qualifying_activity }

    it 'partitions QAs by date' do
      pre_enrollment_activity.calculate_payability!
      qualifying_activity.calculate_payability!

      expect(pre_enrollment_activity.naturally_payable).to be true
      expect(pre_enrollment_activity.compute_valid_unpayable).to contain_exactly(:outside_enrollment)
      expect(qualifying_activity.naturally_payable).to be true
    end
  end

  describe 'with multiple referrals' do
    let(:pre_enrollment_activity) { create :qualifying_activity_for_patient_a, :old_qa }
    let(:qualifying_activity) { create :qualifying_activity_for_patient_a }

    it 'partitions QAs by date' do
      pre_enrollment_activity.calculate_payability!
      qualifying_activity.calculate_payability!

      expect(pre_enrollment_activity.naturally_payable).to be true
      expect(pre_enrollment_activity.compute_valid_unpayable).to contain_exactly(:outside_enrollment)
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
        expect(unpayable_outreach.compute_valid_unpayable).to contain_exactly(:outreach_past_cutoff)
      end
    end

    it 'makes non-outreach QAs payable until the engagement date' do
      enrollment_start_date = @referral.enrollment_start_date
      payable_qa = create :qualifying_activity, patient: @patient, activity: :community_connection, date_of_activity: enrollment_start_date + 120.days
      unpayable_qa = create :qualifying_activity, patient: @patient, activity: :community_connection, date_of_activity: enrollment_start_date + 180.days

      Timecop.travel(enrollment_start_date + 240.days)
      aggregate_failures do
        expect(payable_qa.compute_valid_unpayable?).to be false
        expect(unpayable_qa.compute_valid_unpayable).to contain_exactly(:activity_outside_of_engagement_without_careplan)
      end
    end

    it 'keeps non-outreach QAs payable after the engagement date with a pctp_signed QA' do
      enrollment_start_date = @referral.enrollment_start_date
      now_payable_qa = create :qualifying_activity, patient: @patient, activity: :community_connection, date_of_activity: enrollment_start_date + 180.days
      create(
        :careplan,
        patient: @patient,
        provider_signed_on: enrollment_start_date + 30.days,
        provider_signature_mode: :in_person,
        patient_signed_on: enrollment_start_date + 30.days,
        patient_signature_mode: :in_person,
      )
      create :qualifying_activity, patient: @patient, activity: :pctp_signed, date_of_activity: enrollment_start_date + 30.days

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
        expect(unpayable_outreach.compute_valid_unpayable).to contain_exactly(:outside_enrollment)
      end
    end

    it 'ignores non-contributing referrals' do
      enrollment_start_date = @referral.enrollment_start_date
      careplan = create(
        :careplan,
        patient: @patient,
        provider_signed_on: enrollment_start_date + 30.days,
        provider_signature_mode: :in_person,
        patient_signed_on: enrollment_start_date + 30.days,
        patient_signature_mode: :in_person,
      )
      create :qualifying_activity, patient: @patient, activity: :pctp_signed, date_of_activity: enrollment_start_date + 30.days
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

    it 'adds a PCTP-signed QA on a re-enrollment' do
      enrollment_start_date = @referral.enrollment_start_date
      careplan = create(
        :careplan,
        patient: @patient,
        provider_signed_on: enrollment_start_date + 30.days,
        provider_signature_mode: :in_person,
        patient_signed_on: enrollment_start_date + 30.days,
        patient_signature_mode: :in_person,
      )
      create :qualifying_activity, patient: @patient, activity: :pctp_signed, date_of_activity: enrollment_start_date + 30.days
      @patient.patient_referral.update(disenrollment_date: enrollment_start_date + 59.days)
      new_enrollment_date = careplan.expires_on - 1.month
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

      aggregate_failures do
        expect(@patient.qualifying_activities.count).to eq(2)

        @patient.qualifying_activities.each do |qa|
          expect(qa.activity).to eq 'pctp_signed'
        end
      end
    end
  end

  describe 'repetition scenarios' do
    let!(:data_source) { create :health_data_source }
    let!(:referral_ds) { create :referral_ds }

    before(:each) do
      Timecop.travel(Date.parse('2018-01-01')) # Enrollment durations depend on time if there is no disenrollment date
      referral_args = {
        first_name: 'First',
        last_name: 'Last',
        birthdate: Date.current,
        medicaid_id: Faker::Number.number(digits: 10),
        enrollment_start_date: Date.parse('2018-01-10'),
      }
      @referral = Health::PatientReferral.create_referral(nil, referral_args)
      @referral.convert_to_patient
      @patient = @referral.patient
    end

    after(:each) do
      Timecop.return
    end

    it 'allows 3 outreach QAs before the cut-off, and not more than 1 per month' do
      outreach_qa1 = create :qualifying_activity, patient: @patient, activity: :outreach, date_of_activity: Date.parse('2018-01-15')
      outreach_qa2 = create :qualifying_activity, patient: @patient, activity: :outreach, date_of_activity: Date.parse('2018-01-20')
      outreach_qa3 = create :qualifying_activity, patient: @patient, activity: :outreach, date_of_activity: Date.parse('2018-02-15')
      outreach_qa4 = create :qualifying_activity, patient: @patient, activity: :outreach, date_of_activity: Date.parse('2018-03-15')
      outreach_qa5 = create :qualifying_activity, patient: @patient, activity: :outreach, date_of_activity: Date.parse('2018-04-05')
      outreach_qa6 = create :qualifying_activity, patient: @patient, activity: :outreach, date_of_activity: Date.parse('2018-04-20')

      Timecop.return
      aggregate_failures do
        expect(outreach_qa1.compute_valid_unpayable?).to be false
        expect(outreach_qa2.compute_valid_unpayable).to contain_exactly(:limit_outreaches_per_month_exceeded)
        expect(outreach_qa3.compute_valid_unpayable?).to be false
        expect(outreach_qa4.compute_valid_unpayable?).to be false
        expect(outreach_qa5.compute_valid_unpayable).to contain_exactly(:limit_months_outreach_exceeded)
        expect(outreach_qa6.compute_valid_unpayable).to contain_exactly(:limit_months_outreach_exceeded, :limit_outreaches_per_month_exceeded, :outreach_past_cutoff)
      end
    end

    it 'allows 5 non-outreach QAs before the engagement date, and not more than 1 per month' do
      other_qa1 = create :qualifying_activity, patient: @patient, activity: :community_connection, date_of_activity: Date.parse('2018-01-15')
      other_qa2 = create :qualifying_activity, patient: @patient, activity: :community_connection, date_of_activity: Date.parse('2018-02-05')
      other_qa3 = create :qualifying_activity, patient: @patient, activity: :community_connection, date_of_activity: Date.parse('2018-02-10')
      other_qa4 = create :qualifying_activity, patient: @patient, activity: :community_connection, date_of_activity: Date.parse('2018-03-15')
      other_qa5 = create :qualifying_activity, patient: @patient, activity: :community_connection, date_of_activity: Date.parse('2018-04-15')
      other_qa6 = create :qualifying_activity, patient: @patient, activity: :community_connection, date_of_activity: Date.parse('2018-05-15')
      other_qa7 = create :qualifying_activity, patient: @patient, activity: :community_connection, date_of_activity: Date.parse('2018-06-05')
      other_qa8 = create :qualifying_activity, patient: @patient, activity: :community_connection, date_of_activity: Date.parse('2018-06-25')

      Timecop.return
      aggregate_failures do
        expect(other_qa1.compute_valid_unpayable?).to be false
        expect(other_qa2.compute_valid_unpayable?).to be false
        expect(other_qa3.compute_valid_unpayable).to contain_exactly(:limit_activities_per_month_without_careplan_exceeded)
        expect(other_qa4.compute_valid_unpayable?).to be false
        expect(other_qa5.compute_valid_unpayable?).to be false
        expect(other_qa6.compute_valid_unpayable?).to be false
        expect(other_qa7.compute_valid_unpayable).to contain_exactly(:limit_months_without_careplan_exceeded)
        expect(other_qa8.compute_valid_unpayable).to contain_exactly(:limit_activities_per_month_without_careplan_exceeded, :activity_outside_of_engagement_without_careplan, :limit_months_without_careplan_exceeded)
      end
    end

    it 'outreach and non-outreach QAs don\'t interact' do
      outreach_qa1 = create :qualifying_activity, patient: @patient, activity: :outreach, date_of_activity: Date.parse('2018-01-15')
      outreach_qa2 = create :qualifying_activity, patient: @patient, activity: :outreach, date_of_activity: Date.parse('2018-01-20')
      outreach_qa3 = create :qualifying_activity, patient: @patient, activity: :outreach, date_of_activity: Date.parse('2018-02-15')
      outreach_qa4 = create :qualifying_activity, patient: @patient, activity: :outreach, date_of_activity: Date.parse('2018-03-15')
      outreach_qa5 = create :qualifying_activity, patient: @patient, activity: :outreach, date_of_activity: Date.parse('2018-04-05')
      outreach_qa6 = create :qualifying_activity, patient: @patient, activity: :outreach, date_of_activity: Date.parse('2018-04-20')

      other_qa1 = create :qualifying_activity, patient: @patient, activity: :community_connection, date_of_activity: Date.parse('2018-01-15')
      other_qa2 = create :qualifying_activity, patient: @patient, activity: :community_connection, date_of_activity: Date.parse('2018-02-05')
      other_qa3 = create :qualifying_activity, patient: @patient, activity: :community_connection, date_of_activity: Date.parse('2018-02-10')
      other_qa4 = create :qualifying_activity, patient: @patient, activity: :community_connection, date_of_activity: Date.parse('2018-03-15')
      other_qa5 = create :qualifying_activity, patient: @patient, activity: :community_connection, date_of_activity: Date.parse('2018-04-15')
      other_qa6 = create :qualifying_activity, patient: @patient, activity: :community_connection, date_of_activity: Date.parse('2018-05-15')
      other_qa7 = create :qualifying_activity, patient: @patient, activity: :community_connection, date_of_activity: Date.parse('2018-06-05')
      other_qa8 = create :qualifying_activity, patient: @patient, activity: :community_connection, date_of_activity: Date.parse('2018-06-25')

      Timecop.return
      aggregate_failures do
        expect(outreach_qa1.compute_valid_unpayable?).to be false
        expect(outreach_qa2.compute_valid_unpayable).to contain_exactly(:limit_outreaches_per_month_exceeded)
        expect(outreach_qa3.compute_valid_unpayable?).to be false
        expect(outreach_qa4.compute_valid_unpayable?).to be false
        expect(outreach_qa5.compute_valid_unpayable).to contain_exactly(:limit_months_outreach_exceeded)
        expect(outreach_qa6.compute_valid_unpayable).to contain_exactly(:outreach_past_cutoff, :limit_outreaches_per_month_exceeded, :limit_months_outreach_exceeded)

        expect(other_qa1.compute_valid_unpayable?).to be false
        expect(other_qa2.compute_valid_unpayable?).to be false
        expect(other_qa3.compute_valid_unpayable).to contain_exactly(:limit_activities_per_month_without_careplan_exceeded)
        expect(other_qa4.compute_valid_unpayable?).to be false
        expect(other_qa5.compute_valid_unpayable?).to be false
        expect(other_qa6.compute_valid_unpayable?).to be false
        expect(other_qa7.compute_valid_unpayable).to contain_exactly(:limit_months_without_careplan_exceeded)
        expect(other_qa8.compute_valid_unpayable).to contain_exactly(:limit_activities_per_month_without_careplan_exceeded, :activity_outside_of_engagement_without_careplan, :limit_months_without_careplan_exceeded)
      end
    end

    it 'ignores unpayable outreach QAs when checking for first' do
      create :qualifying_activity, patient: @patient, activity: :outreach, date_of_activity: Date.parse('2018-01-15'), naturally_payable: true, valid_unpayable: true
      outreach_qa = create :qualifying_activity, patient: @patient, activity: :outreach, date_of_activity: Date.parse('2018-01-20')

      Timecop.return
      expect(outreach_qa.compute_valid_unpayable?).to be false
    end
  end

  describe 'Outreach QA' do
    let(:qa) { create :valid_qa }

    it 'has a valid procedure code' do
      qa.maintain_cached_values

      expect(qa.naturally_payable).to be true
      expect(qa.procedure_valid?).to be true
      expect(qa.procedure_code).to eq 'G9011'
    end
  end

  describe 'PCTP QA' do
    let(:qa) { create :pctp_signed_qa }

    it 'has a valid procedure code' do
      qa.maintain_cached_values

      expect(qa.naturally_payable).to be true
      expect(qa.procedure_valid?).to be true
      expect(qa.procedure_code).to eq 'T2024>U4'
    end
  end

  describe 'CHA QA' do
    let(:qa) { create :cha_qa }
    let(:phone_qa) { create :cha_qa, mode_of_contact: :phone_call }

    it 'has a valid procedure code' do
      qa.maintain_cached_values

      expect(qa.naturally_payable).to be true
      expect(qa.procedure_valid?).to be true
      expect(qa.procedure_code).to eq 'G0506'
      expect(qa.modifiers).to contain_exactly('U1')
    end

    it 'marks phone_calls as in person' do
      TodoOrDie('Remove MH COVID flexibility', by: '2023-01-01')
      phone_qa.maintain_cached_values

      expect(phone_qa.naturally_payable).to be true
      expect(phone_qa.procedure_valid?).to be true
      expect(phone_qa.modifiers).to contain_exactly('U1', 'U2')
      # expect(phone_qa.modifiers).to contain_exactly('U1', 'U3')
    end
  end

  describe 'Discharge follow up QA' do
    let(:qa) { create :discharge_follow_up_qa }
    let(:phone_qa) { create :discharge_follow_up_qa, mode_of_contact: :phone_call }

    it 'has a valid procedure code' do
      qa.maintain_cached_values

      expect(qa.naturally_payable).to be true
      expect(qa.procedure_valid?).to be true
      expect(qa.procedure_code).to eq 'G9007>U5'
      expect(qa.modifiers).to contain_exactly('U1')
    end

    it 'marks phone_calls as in person' do
      TodoOrDie('Remove MH COVID flexibility', by: '2023-01-01')
      phone_qa.maintain_cached_values

      expect(phone_qa.naturally_payable).to be true
      expect(phone_qa.procedure_valid?).to be true
      expect(phone_qa.modifiers).to contain_exactly('U1', 'U2')
      # expect(phone_qa.modifiers).to contain_exactly('U1', U3')
    end
  end
end
