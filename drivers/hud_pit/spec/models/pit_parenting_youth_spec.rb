# frozen_string_literal: true

require 'rails_helper'
require_relative 'hud_pit_context'

RSpec.describe 'PIT Parenting Youth Counts', type: :model do
  include_context 'HUD pit context'

  let(:question) { HudPit::Generators::Pit::Fy2025::ParentingYouth::QUESTION_NUMBER }
  let(:es_project) { create_project(project_type: 0) } # ES-EE

  # DOBs for precise age calculations relative to pit_date
  let(:dob_child_5) { pit_date - 5.years }
  let(:dob_youth_17) { pit_date - 17.years } # Parenting youth < 18
  let(:dob_youth_18) { pit_date - 18.years } # Parenting youth 18-24
  let(:dob_youth_22) { pit_date - 22.years } # Parenting youth 18-24
  let(:dob_youth_24) { pit_date - 24.years } # Parenting youth 18-24
  let(:dob_adult_25) { pit_date - 25.years } # Too old for parenting youth household max_age filter
  let(:question) { HudPit::Generators::Pit::Fy2025::VeteranAdults::QUESTION_NUMBER }

  describe 'Parenting Youth (HoH/Spouse, 18-24)' do
    context 'when HoH is 18-24, with a child, and max household age < 25' do
      before do
        household_id = 'py_youth_hoh_18_24_valid'
        # HoH aged 22
        hoh_client = create_client_with_warehouse_link(uid: 'py_hoh_22', dob: dob_youth_22)
        create_enrollment(
          client: hoh_client,
          project: es_project,
          entry_date: pit_date,
          relationship_to_ho_h: 1, # HoH
          household_id: household_id,
        )
        # Child aged 5
        child_client = create_client_with_warehouse_link(uid: 'py_child_5_for_hoh22', dob: dob_child_5)
        create_enrollment(
          client: child_client,
          project: es_project,
          entry_date: pit_date,
          relationship_to_ho_h: 3, # Child
          household_id: household_id,
        )
      end

      it 'counts the HoH as a parenting youth 18-24' do
        report = run_report(questions: [question])
        # :youth_hoh is cell B8 for ParentingYouth question
        parenting_youth_18_24_count = report.answer(question: question, cell: 'B8')
        expect(parenting_youth_18_24_count.value).to eq(1)
      end
    end

    context 'when spouse (RelToHoH=2 or 4) is 18-24, HoH might be older but <25, with a child' do
      # The sub_calculation is hoh_or_spouse.and(age_ranges['18-24'])
      # RelationshipToHoH codes: 1=Self(HoH), 2=HoH's spouse/partner, 3=HoH's child, 4=Other relation member
      # HUD defines spouse/partner for this purpose potentially differently; check base.rb hoh_or_spouse method.
      # Base.rb uses: a_t[:relationship_to_hoh].in([1, 2, 4]) which implies HoH, spouse/partner, or other adult related to HoH.
      # For this test, we will use relationship 2 (spouse/partner).

      before do
        household_id = 'py_spouse_18_24_valid'
        # HoH aged 23 (also fits 18-24 but we are testing the spouse)
        hoh_client = create_client_with_warehouse_link(uid: 'py_hoh_23_for_spouse', dob: pit_date - 23.years)
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: 1, household_id: household_id)

        # Spouse aged 22
        spouse_client = create_client_with_warehouse_link(uid: 'py_spouse_22', dob: dob_youth_22)
        create_enrollment(client: spouse_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: 2, household_id: household_id)

        # Child aged 5
        child_client = create_client_with_warehouse_link(uid: 'py_child_5_for_spouse22', dob: dob_child_5)
        create_enrollment(client: child_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: 3, household_id: household_id)
      end

      it 'counts both HoH and spouse if both are 18-24' do
        report = run_report(questions: [question])
        parenting_youth_18_24_count = report.answer(question: question, cell: 'B8')
        expect(parenting_youth_18_24_count.value).to eq(2) # Both HoH (23) and Spouse (22) are 18-24
      end
    end

    context 'when HoH is 18-24, but no child present' do
      before do
        household_id = 'py_youth_hoh_18_24_no_child'
        hoh_client = create_client_with_warehouse_link(uid: 'py_hoh_22_no_child', dob: dob_youth_22)
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: 1, household_id: household_id)
        # Another youth, but not a child of HoH for household_type purposes
        other_youth = create_client_with_warehouse_link(uid: 'py_other_youth_no_child', dob: dob_youth_18)
        create_enrollment(client: other_youth, project: es_project, entry_date: pit_date, relationship_to_ho_h: 4, household_id: household_id)
      end

      it 'does not count as parenting youth household (due to household_type filter)' do
        # This household would be filtered out by ParentingYouth.filter_pending_associations
        # because row[:household_type].to_s == 'adults_and_children' will be false.
        report = run_report(questions: [question])
        parenting_youth_18_24_count = report.answer(question: question, cell: 'B8')
        expect(parenting_youth_18_24_count.value).to eq(0)
      end
    end

    context 'when HoH is 18-24, with child, but another member is >= 25' do
      before do
        household_id = 'py_youth_hoh_18_24_adult_too_old'
        hoh_client = create_client_with_warehouse_link(uid: 'py_hoh_22_adult_old', dob: dob_youth_22)
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: 1, household_id: household_id)

        child_client = create_client_with_warehouse_link(uid: 'py_child_5_adult_old', dob: dob_child_5)
        create_enrollment(client: child_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: 3, household_id: household_id)

        older_adult = create_client_with_warehouse_link(uid: 'py_adult_25', dob: dob_adult_25)
        create_enrollment(client: older_adult, project: es_project, entry_date: pit_date, relationship_to_ho_h: 4, household_id: household_id)
      end

      it 'does not count as parenting youth household (due to max_age filter)' do
        # This household would be filtered out by ParentingYouth.filter_pending_associations
        # because row[:max_age] < 25 will be false.
        report = run_report(questions: [question])
        parenting_youth_18_24_count = report.answer(question: question, cell: 'B8')
        expect(parenting_youth_18_24_count.value).to eq(0)
      end
    end

    context 'when HoH is < 18 (e.g. 17), with a child' do
      before do
        household_id = 'py_youth_hoh_17_valid'
        hoh_client = create_client_with_warehouse_link(uid: 'py_hoh_17', dob: dob_youth_17)
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: 1, household_id: household_id)

        child_client = create_client_with_warehouse_link(uid: 'py_child_5_for_hoh17', dob: dob_child_5)
        create_enrollment(client: child_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: 3, household_id: household_id)
      end

      it 'counts 0 for the 18-24 parenting youth category' do
        report = run_report(questions: [question])
        parenting_youth_18_24_count = report.answer(question: question, cell: 'B8')
        expect(parenting_youth_18_24_count.value).to eq(0)
      end
    end
  end

  describe 'Parenting Youth (HoH/Spouse, <18)' do
    context 'when HoH is <18, with a child, and max household age < 25' do
      before do
        household_id = 'py_child_hoh_under_18_valid'
        # HoH aged 17
        hoh_client = create_client_with_warehouse_link(uid: 'py_hoh_17_u18', dob: dob_youth_17)
        create_enrollment(
          client: hoh_client,
          project: es_project,
          entry_date: pit_date,
          relationship_to_ho_h: 1, # HoH
          household_id: household_id,
        )
        # Child aged 5
        child_client = create_client_with_warehouse_link(uid: 'py_child_5_for_hoh17_u18', dob: dob_child_5)
        create_enrollment(
          client: child_client,
          project: es_project,
          entry_date: pit_date,
          relationship_to_ho_h: 3, # Child
          household_id: household_id,
        )
      end

      it 'counts the HoH as a parenting youth <18' do
        report = run_report(questions: [question])
        # :child_hoh is cell B6 for ParentingYouth question
        parenting_youth_under_18_count = report.answer(question: question, cell: 'B6')
        expect(parenting_youth_under_18_count.value).to eq(1)
      end
    end

    context 'when spouse is <18, HoH also <18, with a child, max household age < 25' do
      before do
        household_id = 'py_child_spouse_under_18_valid'
        # HoH aged 17
        hoh_client = create_client_with_warehouse_link(uid: 'py_hoh_17_for_spouse_u18', dob: dob_youth_17)
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: 1, household_id: household_id)

        # Spouse aged 16
        spouse_client = create_client_with_warehouse_link(uid: 'py_spouse_16_u18', dob: pit_date - 16.years)
        create_enrollment(client: spouse_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: 2, household_id: household_id)

        # Child aged 2
        child_client = create_client_with_warehouse_link(uid: 'py_child_2_for_spouse16_u18', dob: pit_date - 2.years)
        create_enrollment(client: child_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: 3, household_id: household_id)
      end

      it 'counts both HoH and spouse if both are <18' do
        report = run_report(questions: [question])
        parenting_youth_under_18_count = report.answer(question: question, cell: 'B6')
        expect(parenting_youth_under_18_count.value).to eq(2) # Both HoH (17) and Spouse (16) are <18
      end
    end

    context 'when HoH is <18, but no child present' do
      before do
        household_id = 'py_child_hoh_under_18_no_child'
        hoh_client = create_client_with_warehouse_link(uid: 'py_hoh_17_no_child_u18', dob: dob_youth_17)
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: 1, household_id: household_id)
      end

      it 'does not count (due to household_type filter)' do
        report = run_report(questions: [question])
        parenting_youth_under_18_count = report.answer(question: question, cell: 'B6')
        expect(parenting_youth_under_18_count.value).to eq(0)
      end
    end

    context 'when HoH is <18, with child, but another member is >= 25' do
      before do
        household_id = 'py_child_hoh_under_18_adult_too_old'
        hoh_client = create_client_with_warehouse_link(uid: 'py_hoh_17_adult_old_u18', dob: dob_youth_17)
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: 1, household_id: household_id)

        child_client = create_client_with_warehouse_link(uid: 'py_child_5_adult_old_u18', dob: dob_child_5)
        create_enrollment(client: child_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: 3, household_id: household_id)

        older_adult = create_client_with_warehouse_link(uid: 'py_adult_25_u18hh', dob: dob_adult_25)
        create_enrollment(client: older_adult, project: es_project, entry_date: pit_date, relationship_to_ho_h: 4, household_id: household_id)
      end

      it 'does not count (due to max_age filter)' do
        report = run_report(questions: [question])
        parenting_youth_under_18_count = report.answer(question: question, cell: 'B6')
        expect(parenting_youth_under_18_count.value).to eq(0)
      end
    end

    context 'when HoH is 18, with a child' do
      before do
        household_id = 'py_child_hoh_18_valid'
        hoh_client = create_client_with_warehouse_link(uid: 'py_hoh_18', dob: dob_youth_18)
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: 1, household_id: household_id)

        child_client = create_client_with_warehouse_link(uid: 'py_child_5_for_hoh18', dob: dob_child_5)
        create_enrollment(client: child_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: 3, household_id: household_id)
      end

      it 'counts 0 for the <18 parenting youth category' do
        report = run_report(questions: [question])
        parenting_youth_under_18_count = report.answer(question: question, cell: 'B6')
        expect(parenting_youth_under_18_count.value).to eq(0)
      end
    end
  end

  # Tests for parenting youth counts
end
