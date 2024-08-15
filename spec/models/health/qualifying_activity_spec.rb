require 'rails_helper'
require 'faker'

RSpec.describe Health::QualifyingActivity, type: :model do
  let!(:patient) { create :patient }
  let!(:current_referral) { create :current_referral, patient_id: patient.id }

  describe 'with multiple referrals' do
    let!(:qualifying_activity) { create :qualifying_activity, patient_id: patient.id, date_of_activity: Date.current }
    let!(:prior_referral) { create :prior_referral, patient_id: patient.id }
    let!(:pre_enrollment_activity) { create :qualifying_activity, date_of_activity: Date.current - 10.months, patient_id: qualifying_activity.patient_id }

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
      travel_to(Date.current - 2.years) # Enrollment durations depend on time if there is no disenrollment date
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
      travel_back
    end

    it 'makes outreach QAs payable until the cutoff' do
      enrollment_start_date = @referral.enrollment_start_date
      payable_outreach = create :qualifying_activity, patient: @patient, activity: :outreach, date_of_activity: enrollment_start_date + 30.days
      unpayable_outreach = create :qualifying_activity, patient: @patient, activity: :outreach, date_of_activity: enrollment_start_date + 120.days

      travel_to(enrollment_start_date + 240.days)
      aggregate_failures do
        expect(payable_outreach.compute_valid_unpayable?).to be false
        expect(unpayable_outreach.compute_valid_unpayable).to contain_exactly(:outreach_past_cutoff)
      end
    end

    it 'makes non-outreach QAs payable until the engagement date' do
      enrollment_start_date = @referral.enrollment_start_date
      payable_qa = create :qualifying_activity, patient: @patient, activity: :community_connection, date_of_activity: enrollment_start_date + 120.days
      unpayable_qa = create :qualifying_activity, patient: @patient, activity: :community_connection, date_of_activity: enrollment_start_date + 180.days

      travel_to(enrollment_start_date + 240.days)
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

      travel_to(enrollment_start_date + 240.days)
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

      payable_outreach = create :qualifying_activity, patient: @patient, activity: :outreach, date_of_activity: re_enrollment_date + 16.days
      unpayable_outreach = create :qualifying_activity, patient: @patient, activity: :outreach, date_of_activity: enrollment_start_date + 75.days

      travel_to(enrollment_start_date + 240.days)
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
      travel_to(new_enrollment_date)
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

      travel_to(new_enrollment_date + 240.days)
      aggregate_failures do
        expect(payable_outreach.compute_valid_unpayable?).to be false
        expect(payable_qa.compute_valid_unpayable?).to be false
      end
    end

    xit 'adds a PCTP-signed QA on a re-enrollment' do
      # 4/3/24 - re-enrollment QAs are disabled pending dicussion
      enrollment_start_date = @referral.enrollment_start_date
      careplan = create(
        :cp2_careplan,
        patient: @patient,
        patient_signed_on: enrollment_start_date + 30.days,
        careplan_sent_on: enrollment_start_date + 30.days,
      )
      create(:pctp_careplan, patient_id: @patient.id, instrument: careplan)
      create :qualifying_activity, patient: @patient, activity: :pctp_signed, date_of_activity: enrollment_start_date + 30.days
      @patient.patient_referral.update(disenrollment_date: enrollment_start_date + 59.days)
      new_enrollment_date = careplan.expires_on - 1.month
      travel_to(new_enrollment_date)
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
      travel_to(Date.parse('2018-01-01')) # Enrollment durations depend on time if there is no disenrollment date
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
      travel_back
    end

    it 'allows 3 outreach QAs before the cut-off, and not more than 1 per month' do
      outreach_qa1 = create :qualifying_activity, patient: @patient, activity: :outreach, date_of_activity: Date.parse('2018-01-15')
      outreach_qa2 = create :qualifying_activity, patient: @patient, activity: :outreach, date_of_activity: Date.parse('2018-01-20')
      outreach_qa3 = create :qualifying_activity, patient: @patient, activity: :outreach, date_of_activity: Date.parse('2018-02-15')
      outreach_qa4 = create :qualifying_activity, patient: @patient, activity: :outreach, date_of_activity: Date.parse('2018-03-15')
      outreach_qa5 = create :qualifying_activity, patient: @patient, activity: :outreach, date_of_activity: Date.parse('2018-04-05')
      outreach_qa6 = create :qualifying_activity, patient: @patient, activity: :outreach, date_of_activity: Date.parse('2018-04-20')

      travel_back
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

      travel_back
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

      travel_back
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

      travel_back
      expect(outreach_qa.compute_valid_unpayable?).to be false
    end
  end

  describe 'Outreach QA' do
    let(:qa) { create :valid_qa, patient_id: patient.id, date_of_activity: Date.current }

    it 'has a valid procedure code' do
      qa.maintain_cached_values

      expect(qa.naturally_payable).to be true
      expect(qa.procedure_valid?).to be true
      expect(qa.procedure_code).to eq 'G9011'
    end
  end

  describe 'PCTP QA' do
    let(:qa) { create :pctp_signed_qa, patient_id: patient.id, reached_client: :no, date_of_activity: Date.current }

    it 'has a valid procedure code' do
      qa.maintain_cached_values

      expect(qa.naturally_payable).to be true
      expect(qa.procedure_valid?).to be true
      expect(qa.procedure_with_modifiers).to eq 'T2024>U4'
    end
  end

  describe 'CHA QA' do
    let(:qa) { create :cha_qa, patient_id: patient.id, date_of_activity: Date.current }

    it 'has a valid procedure code' do
      qa.maintain_cached_values

      expect(qa.naturally_payable).to be true
      expect(qa.procedure_valid?).to be true
      expect(qa.procedure_code).to eq 'G0506'
      expect(qa.modifiers).to contain_exactly('U1')
    end
  end

  describe 'Discharge follow up QA' do
    let(:qa) { create :discharge_follow_up_qa, patient_id: patient.id, date_of_activity: Date.current }

    it 'has a valid procedure code' do
      qa.maintain_cached_values

      expect(qa.naturally_payable).to be true
      expect(qa.procedure_valid?).to be true
      expect(qa.procedure_with_modifiers).to eq 'T2038>U1>U5'
    end
  end

  describe '2024 phone coding changes' do
    let(:phone_qa) { create :discharge_follow_up_qa, mode_of_contact: :phone_call, patient_id: patient.id, date_of_activity: Date.current }

    it 'is a U3 before 2024-01-01' do
      phone_qa.date_of_activity = '2023-12-31'.to_date
      expect(phone_qa.modifiers).to include('U3')
    end

    it 'is a 93 on 2024-01-01' do
      phone_qa.date_of_activity = '2024-01-01'.to_date
      expect(phone_qa.modifiers).to include('93')
    end

    it 'is still a U3 if it was a collateral contact' do
      phone_qa.date_of_activity = '2024-01-01'.to_date
      phone_qa.reached_client = :collateral
      expect(phone_qa.modifiers).to include('U3')
    end
  end

  describe '2024 care team contact changes' do
    let(:qa) { create :care_team_qa, patient_id: patient.id, date_of_activity: Date.current }
    it 'codes an in person meeting that includes the client as face to face' do
      qa.mode_of_contact = :in_person
      qa.reached_client = :yes

      expect(qa.modifiers).to contain_exactly('U1', 'U2')
    end

    it "codes an in person meeting that doesn't include the client as face to face" do
      qa.mode_of_contact = :in_person
      qa.reached_client = :no

      expect(qa.modifiers).to contain_exactly('U2')
    end

    it 'codes an in person meeting that is marked as collateral as face to face' do
      qa.mode_of_contact = :in_person
      qa.reached_client = :collateral

      expect(qa.modifiers).to contain_exactly('U2')
    end

    it 'codes a phone call that includes the client as telehealth' do
      qa.mode_of_contact = :phone_call
      qa.reached_client = :yes

      expect(qa.modifiers).to contain_exactly('U1', '93')
    end

    it "codes a phone call that doesn't include the client as indirect" do
      qa.mode_of_contact = :phone_call
      qa.reached_client = :no

      expect(qa.modifiers).to contain_exactly('U3')
    end

    it 'codes a phone call that is marked as a collateral as indirect and not as collateral' do
      qa.mode_of_contact = :phone_call
      qa.reached_client = :collateral

      expect(qa.modifiers).to contain_exactly('U3')
    end
  end
end
