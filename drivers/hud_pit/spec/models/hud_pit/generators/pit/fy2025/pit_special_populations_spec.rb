# frozen_string_literal: true

require 'rails_helper'
require_relative 'hud_pit_context'

RSpec.describe 'PIT Special Population Counts', type: :model do
  include_context 'HUD pit context'

  let(:question) { HudPit::Generators::Pit::Fy2025::AdditionalHomelessPopulations::QUESTION_NUMBER }
  let(:es_project) { create_project(project_type: 0) }
  let(:pit_report_date) { pit_date }
  let(:adult_dob) { pit_report_date - 30.years }
  let(:young_adult_dob) { pit_report_date - 20.years } # For adult checks
  let(:child_dob) { pit_report_date - 10.years } # To ensure not counted if filter is adult-only

  let(:disability_types) do
    GrdaWarehouse::Hud::Disability.disability_types.invert
  end

  # Helper to create and enroll a client, then attach condition records
  def create_client_with_conditions(uid:, household_id:, dob:, conditions: {}, is_hoh: true, entry_date_offset: -10)
    client = create_client_with_warehouse_link(uid: uid, dob: dob)
    enrollment = create_enrollment(
      client: client,
      project: es_project,
      entry_date: pit_report_date + entry_date_offset.days,
      relationship_to_ho_h: is_hoh ? 1 : 3, # Adjust if testing non-HoH adults
      household_id: household_id,
    )

    if conditions[:mental_illness]
      create_disability(
        enrollment: enrollment,
        information_date: pit_report_date - 1.day, # Ensure info is current
        disability_type: disability_types[:mental], # Mental Health Problem
        disability_response: conditions[:mental_illness], # 1 for Yes
      )
    end

    if conditions[:substance_use]
      # Assuming type 4 (Alcohol) for simplicity, sub_calculation checks any substance type
      create_disability(
        enrollment: enrollment,
        information_date: pit_report_date - 1.day,
        disability_type: disability_types[:substance],
        disability_response: conditions[:substance_use], # 1 for Yes
      )
    end

    if conditions[:hiv_aids]
      create_disability(
        enrollment: enrollment,
        information_date: pit_report_date - 1.day,
        disability_type: disability_types[:hiv],
        disability_response: conditions[:hiv_aids], # 1 for Yes
      )
    end

    if conditions[:domestic_violence_survivor]
      create_health_and_dv(
        enrollment: enrollment,
        information_date: pit_report_date - 1.day,
        domestic_violence_survivor: conditions[:domestic_violence_survivor], # 1 for Yes
        currently_fleeing: conditions[:domestic_violence_survivor] == 1,
      )
    end
    client
  end

  describe 'Adults with a Serious Mental Illness' do
    context 'when an adult client has a mental illness disability' do
      before do
        create_client_with_conditions(
          uid: 'adult_mi_yes',
          household_id: 'hh_adult_mi_yes',
          dob: adult_dob,
          conditions: { mental_illness: 1 }, # Yes
        )
      end

      it 'counts the client' do
        report = run_report(questions: [question])
        # :adults_with_mental_illness is B2 for AdditionalHomelessPopulations
        count = report.answer(question: question, cell: 'B2')
        expect(count.value).to eq(1)
      end
    end

    context 'when an adult client does not have a mental illness disability' do
      before do
        create_client_with_conditions(
          uid: 'adult_mi_no',
          household_id: 'hh_adult_mi_no',
          dob: adult_dob,
          conditions: { mental_illness: 0 }, # No
        )
      end

      it 'does not count the client' do
        report = run_report(questions: [question])
        count = report.answer(question: question, cell: 'B2')
        expect(count.value).to eq(0)
      end
    end

    context 'when a client has mental illness but is a child' do
      before do
        create_client_with_conditions(
          uid: 'child_mi_yes',
          household_id: 'hh_child_mi_yes',
          dob: child_dob, # Child DOB
          conditions: { mental_illness: 1 },
        )
      end

      it 'does not count the client (due to age filter in AdditionalHomelessPopulations)' do
        # AdditionalHomelessPopulations.filter_pending_associations filters for age >= 18
        report = run_report(questions: [question])
        count = report.answer(question: question, cell: 'B2')
        expect(count.value).to eq(0)
      end
    end

    context 'when an adult client has MI, and another adult in HH also has MI' do
      before do
        household_id = 'hh_adult_mi_multiple'
        create_client_with_conditions(
          uid: 'adult_mi_yes_1',
          household_id: household_id,
          dob: adult_dob,
          conditions: { mental_illness: 1 },
          is_hoh: true,
        )
        create_client_with_conditions(
          uid: 'adult_mi_yes_2',
          household_id: household_id,
          dob: young_adult_dob, # Another adult
          conditions: { mental_illness: 1 },
          is_hoh: false,
        )
      end

      it 'counts both adult clients' do
        report = run_report(questions: [question])
        count = report.answer(question: question, cell: 'B2')
        expect(count.value).to eq(2)
      end
    end
  end

  describe 'Adults with a Substance Use Disorder' do
    context 'when an adult client has a substance use disability' do
      before do
        create_client_with_conditions(
          uid: 'adult_su_yes',
          household_id: 'hh_adult_su_yes',
          dob: adult_dob,
          conditions: { substance_use: 1 }, # Yes to substance use
        )
      end

      it 'counts the client' do
        report = run_report(questions: [question])
        # :adults_with_substance_use is B3 for AdditionalHomelessPopulations
        count = report.answer(question: question, cell: 'B3')
        expect(count.value).to eq(1)
      end
    end

    context 'when an adult client has substance use response type 2 (Yes, awaiting docs)' do
      before do
        create_client_with_conditions(
          uid: 'adult_su_yes_resp2',
          household_id: 'hh_adult_su_yes_resp2',
          dob: adult_dob,
          conditions: { substance_use: 2 }, # Yes, awaiting documentation
        )
      end

      it 'counts the client' do
        report = run_report(questions: [question])
        count = report.answer(question: question, cell: 'B3')
        expect(count.value).to eq(1)
      end
    end

    context 'when an adult client does not have a substance use disability' do
      before do
        create_client_with_conditions(
          uid: 'adult_su_no',
          household_id: 'hh_adult_su_no',
          dob: adult_dob,
          conditions: { substance_use: 0 }, # No
        )
      end

      it 'does not count the client' do
        report = run_report(questions: [question])
        count = report.answer(question: question, cell: 'B3')
        expect(count.value).to eq(0)
      end
    end

    context 'when a client has substance use but is a child' do
      before do
        create_client_with_conditions(
          uid: 'child_su_yes',
          household_id: 'hh_child_su_yes',
          dob: child_dob, # Child DOB
          conditions: { substance_use: 1 },
        )
      end

      it 'does not count the client' do
        report = run_report(questions: [question])
        count = report.answer(question: question, cell: 'B3')
        expect(count.value).to eq(0)
      end
    end
  end

  describe 'Adults with HIV/AIDS' do
    context 'when an adult client has an HIV/AIDS disability' do
      before do
        create_client_with_conditions(
          uid: 'adult_hiv_yes',
          household_id: 'hh_adult_hiv_yes',
          dob: adult_dob,
          conditions: { hiv_aids: 1 }, # Yes to HIV/AIDS
        )
      end

      it 'counts the client' do
        report = run_report(questions: [question])
        # :adults_with_hiv is B4 for AdditionalHomelessPopulations
        count = report.answer(question: question, cell: 'B4')
        expect(count.value).to eq(1)
      end
    end

    context 'when an adult client has HIV/AIDS response type 3 (Yes, client self-reported)' do
      before do
        create_client_with_conditions(
          uid: 'adult_hiv_yes_resp3',
          household_id: 'hh_adult_hiv_yes_resp3',
          dob: adult_dob,
          conditions: { hiv_aids: 3 }, # Yes, client self-reported
        )
      end

      it 'counts the client' do
        report = run_report(questions: [question])
        count = report.answer(question: question, cell: 'B4')
        expect(count.value).to eq(1)
      end
    end

    context 'when an adult client does not have an HIV/AIDS disability' do
      before do
        create_client_with_conditions(
          uid: 'adult_hiv_no',
          household_id: 'hh_adult_hiv_no',
          dob: adult_dob,
          conditions: { hiv_aids: 0 }, # No
        )
      end

      it 'does not count the client' do
        report = run_report(questions: [question])
        count = report.answer(question: question, cell: 'B4')
        expect(count.value).to eq(0)
      end
    end

    context 'when a client has HIV/AIDS but is a child' do
      before do
        create_client_with_conditions(
          uid: 'child_hiv_yes',
          household_id: 'hh_child_hiv_yes',
          dob: child_dob, # Child DOB
          conditions: { hiv_aids: 1 },
        )
      end

      it 'does not count the client' do
        report = run_report(questions: [question])
        count = report.answer(question: question, cell: 'B4')
        expect(count.value).to eq(0)
      end
    end
  end

  describe 'Adult Survivors of Domestic Violence' do
    context 'when an adult client is a DV survivor' do
      before do
        create_client_with_conditions(
          uid: 'adult_dv_yes',
          household_id: 'hh_adult_dv_yes',
          dob: adult_dob,
          conditions: { domestic_violence_survivor: 1 }, # Yes
        )
      end

      it 'counts the client' do
        report = run_report(questions: [question])
        # :adult_dv_survivors is B5 for AdditionalHomelessPopulations
        count = report.answer(question: question, cell: 'B5')
        expect(count.value).to eq(1)
      end
    end

    context 'when an adult client is not a DV survivor' do
      before do
        create_client_with_conditions(
          uid: 'adult_dv_no',
          household_id: 'hh_adult_dv_no',
          dob: adult_dob,
          conditions: { domestic_violence_survivor: 0 }, # No
        )
      end

      it 'does not count the client' do
        report = run_report(questions: [question])
        count = report.answer(question: question, cell: 'B5')
        expect(count.value).to eq(0)
      end
    end

    context 'when a client is a DV survivor but is a child' do
      before do
        create_client_with_conditions(
          uid: 'child_dv_yes',
          household_id: 'hh_child_dv_yes',
          dob: child_dob, # Child DOB
          conditions: { domestic_violence_survivor: 1 },
        )
      end

      it 'does not count the client' do
        report = run_report(questions: [question])
        count = report.answer(question: question, cell: 'B5')
        expect(count.value).to eq(0)
      end
    end

    context 'when an adult DV survivor has an old HealthAndDV record (info_date > pit_report_date)' do
      before do
        client = create_client_with_warehouse_link(uid: 'adult_dv_old_record', dob: adult_dob)
        enrollment = create_enrollment(
          client: client,
          project: es_project,
          entry_date: pit_report_date - 10.days,
          relationship_to_ho_h: 1,
          household_id: 'hh_adult_dv_old_record',
        )
        create_health_and_dv(
          enrollment: enrollment,
          information_date: pit_report_date + 1.day, # InformationDate is AFTER pit_report_date
          domestic_violence_victim: 1, # Yes
        )
      end

      it 'does not count the client as DV survivor for the PIT date' do
        # The dv_record in Base.rb selects HealthAndDV where InformationDate <= @generator.filter.on
        report = run_report(questions: [question])
        count = report.answer(question: question, cell: 'B5')
        expect(count.value).to eq(0)
      end
    end

    context 'when an adult DV survivor has a HealthAndDV record with nil DomesticViolenceSurvivor' do
      before do
        client = create_client_with_warehouse_link(uid: 'adult_dv_nil_value', dob: adult_dob)
        enrollment = create_enrollment(
          client: client,
          project: es_project,
          entry_date: pit_report_date - 10.days,
          relationship_to_ho_h: 1,
          household_id: 'hh_adult_dv_nil_value',
        )
        create_health_and_dv(
          enrollment: enrollment,
          information_date: pit_report_date - 1.day,
          domestic_violence_victim: nil, # DomesticViolenceSurvivor is nil
        )
      end

      it 'does not count the client as DV survivor' do
        # The dv_record in Base.rb filters for !DomesticViolenceSurvivor.nil?
        report = run_report(questions: [question])
        count = report.answer(question: question, cell: 'B5')
        expect(count.value).to eq(0)
      end
    end
  end
end
