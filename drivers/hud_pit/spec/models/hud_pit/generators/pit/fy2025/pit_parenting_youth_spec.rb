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

  describe 'Parenting Youth (HoH/Spouse, 18-24)' do
    context 'when HoH is 18-24, with a child, and max household age < 25 (single adult HH)' do
      before do
        household_id = 'py_youth_hoh_18_24_valid_single_adult'
        hoh_client = create_client_with_warehouse_link(uid: 'py_hoh_22_single', dob: dob_youth_22)
        create_enrollment(
          client: hoh_client,
          project: es_project,
          entry_date: pit_date,
          relationship_to_ho_h: rel_hoh,
          household_id: household_id,
        )
        child_client = create_client_with_warehouse_link(uid: 'py_child_5_for_hoh22_single', dob: dob_child_5)
        create_enrollment(
          client: child_client,
          project: es_project,
          entry_date: pit_date,
          relationship_to_ho_h: rel_child,
          household_id: household_id,
        )
      end

      it 'counts the HoH as a parenting youth 18-24' do
        report = run_report(questions: [question])
        parenting_youth_18_24_count = report.answer(question: question, cell: 'B8')
        expect(parenting_youth_18_24_count.value).to eq(1)
      end
    end

    context 'when HoH (18-24) and Spouse (18-24) are present with a child (qualifying PYH with two parents)' do
      before do
        household_id = 'py_multi_adult_hoh_spouse_18_24'
        hoh_client = create_client_with_warehouse_link(uid: 'py_hoh_23_multi', dob: pit_date - 23.years)
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_hoh, household_id: household_id)

        spouse_client = create_client_with_warehouse_link(uid: 'py_spouse_22_multi', dob: dob_youth_22)
        create_enrollment(client: spouse_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_spouse, household_id: household_id)

        child_client = create_client_with_warehouse_link(uid: 'py_child_5_for_multi', dob: dob_child_5)
        create_enrollment(client: child_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_child, household_id: household_id)
      end

      it 'counts both HoH and Spouse as parenting youth 18-24' do
        report = run_report(questions: [question])
        parenting_youth_18_24_count = report.answer(question: question, cell: 'B8')
        expect(parenting_youth_18_24_count.value).to eq(2)
      end
    end

    context 'when HoH is 18-24, but no child present (household is adults_only)' do
      before do
        household_id = 'py_youth_hoh_18_24_no_child'
        hoh_client = create_client_with_warehouse_link(uid: 'py_hoh_22_no_child', dob: dob_youth_22)
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_hoh, household_id: household_id)
        other_youth_adult = create_client_with_warehouse_link(uid: 'py_other_youth_no_child_adult', dob: dob_youth_18)
        create_enrollment(client: other_youth_adult, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_other_adult, household_id: household_id)
      end

      it 'counts 0 due to household_type filter (adults_only)' do
        report = run_report(questions: [question])
        parenting_youth_18_24_count = report.answer(question: question, cell: 'B8')
        expect(parenting_youth_18_24_count.value).to eq(0)
      end
    end

    context 'when HoH is 18-24, with child, but another member is >= 25 (filters out household)' do
      before do
        household_id = 'py_youth_hoh_18_24_adult_too_old'
        hoh_client = create_client_with_warehouse_link(uid: 'py_hoh_22_adult_old', dob: dob_youth_22)
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_hoh, household_id: household_id)

        child_client = create_client_with_warehouse_link(uid: 'py_child_5_adult_old', dob: dob_child_5)
        create_enrollment(client: child_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_child, household_id: household_id)

        older_adult = create_client_with_warehouse_link(uid: 'py_adult_25', dob: dob_adult_25)
        create_enrollment(client: older_adult, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_other_adult, household_id: household_id)
      end

      it 'counts 0 due to max_age filter' do
        report = run_report(questions: [question])
        parenting_youth_18_24_count = report.answer(question: question, cell: 'B8')
        expect(parenting_youth_18_24_count.value).to eq(0)
      end
    end

    context 'when HoH is < 18, with a child (single adult HH, but HoH wrong age for this cell)' do
      before do
        household_id = 'py_youth_hoh_17_valid_single_adult'
        hoh_client = create_client_with_warehouse_link(uid: 'py_hoh_17_single', dob: dob_youth_17)
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_hoh, household_id: household_id)

        child_client = create_client_with_warehouse_link(uid: 'py_child_5_for_hoh17_single', dob: dob_child_5)
        create_enrollment(client: child_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_child, household_id: household_id)
      end

      it 'counts 0 for the 18-24 parenting youth category (HoH wrong age)' do
        report = run_report(questions: [question])
        parenting_youth_18_24_count = report.answer(question: question, cell: 'B8')
        expect(parenting_youth_18_24_count.value).to eq(0)
      end
    end
  end

  describe 'Parenting Youth (HoH/Spouse, <18)' do
    context 'when HoH is <18, with a child, and max household age < 25 (HoH <18, no 18+ adult in HH)' do
      before do
        household_id = 'py_child_hoh_under_18_valid_no_18plus_adult'
        hoh_client = create_client_with_warehouse_link(uid: 'py_hoh_17_u18_no_18plus', dob: dob_youth_17)
        create_enrollment(
          client: hoh_client,
          project: es_project,
          entry_date: pit_date,
          relationship_to_ho_h: rel_hoh,
          household_id: household_id,
        )
        child_client = create_client_with_warehouse_link(uid: 'py_child_5_for_hoh17_no_18plus', dob: dob_child_5)
        create_enrollment(
          client: child_client,
          project: es_project,
          entry_date: pit_date,
          relationship_to_ho_h: rel_child,
          household_id: household_id,
        )
      end

      it 'counts 0 because the household is likely filtered out (e.g. as children_only)' do
        report = run_report(questions: [question])
        parenting_youth_under_18_count = report.answer(question: question, cell: 'B6')
        expect(parenting_youth_under_18_count.value).to eq(0)
      end
    end

    context 'when HoH (<18) and Spouse (<18) are present with a child (no 18+ adult in HH)' do
      before do
        household_id = 'py_multi_adult_under_18_no_18plus_adult'
        hoh_client = create_client_with_warehouse_link(uid: 'py_hoh_17_multi_no_18plus', dob: dob_youth_17)
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_hoh, household_id: household_id)

        spouse_client = create_client_with_warehouse_link(uid: 'py_spouse_16_multi_no_18plus', dob: pit_date - 16.years)
        create_enrollment(client: spouse_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_spouse, household_id: household_id)

        child_client = create_client_with_warehouse_link(uid: 'py_child_2_for_multi_no_18plus', dob: pit_date - 2.years)
        create_enrollment(client: child_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_child, household_id: household_id)
      end

      it 'counts 0 because the household is likely filtered out (e.g. as children_only)' do
        report = run_report(questions: [question])
        parenting_youth_under_18_count = report.answer(question: question, cell: 'B6')
        expect(parenting_youth_under_18_count.value).to eq(0)
      end
    end

    context 'when HoH is <18, but no child present (household is adults_only)' do
      before do
        household_id = 'py_child_hoh_under_18_no_child'
        hoh_client = create_client_with_warehouse_link(uid: 'py_hoh_17_no_child_u18', dob: dob_youth_17)
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_hoh, household_id: household_id)
      end

      it 'counts 0 due to household_type filter (adults_only)' do
        report = run_report(questions: [question])
        parenting_youth_under_18_count = report.answer(question: question, cell: 'B6')
        expect(parenting_youth_under_18_count.value).to eq(0)
      end
    end

    context 'when HoH is <18, with child, but another member is >= 25 (filters out HH)' do
      before do
        household_id = 'py_child_hoh_under_18_adult_too_old'
        hoh_client = create_client_with_warehouse_link(uid: 'py_hoh_17_adult_old_u18', dob: dob_youth_17)
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_hoh, household_id: household_id)

        child_client = create_client_with_warehouse_link(uid: 'py_child_5_adult_old_u18', dob: dob_child_5)
        create_enrollment(client: child_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_child, household_id: household_id)

        older_adult = create_client_with_warehouse_link(uid: 'py_adult_25_u18hh', dob: dob_adult_25)
        create_enrollment(client: older_adult, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_other_adult, household_id: household_id)
      end

      it 'counts 0 due to max_age filter' do
        report = run_report(questions: [question])
        parenting_youth_under_18_count = report.answer(question: question, cell: 'B6')
        expect(parenting_youth_under_18_count.value).to eq(0)
      end
    end

    context 'when HoH is 18, with a child (single adult HH, but HoH wrong age for this cell)' do
      before do
        household_id = 'py_child_hoh_18_valid_single_adult'
        hoh_client = create_client_with_warehouse_link(uid: 'py_hoh_18_single', dob: dob_youth_18)
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_hoh, household_id: household_id)

        child_client = create_client_with_warehouse_link(uid: 'py_child_5_for_hoh18_single', dob: dob_child_5)
        create_enrollment(client: child_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_child, household_id: household_id)
      end

      it 'counts 0 for the <18 parenting youth category (HoH wrong age)' do
        report = run_report(questions: [question])
        parenting_youth_under_18_count = report.answer(question: question, cell: 'B6')
        expect(parenting_youth_under_18_count.value).to eq(0)
      end
    end
  end

  describe 'Parenting Youth (Youth Parents Only)' do
    # This tests :hoh_for_youth (B4) which counts individual parenting youth (HoH/Spouse/Other Adult Parent < 25)
    # in a qualifying Parenting Youth Household (all members < 25, adults_and_children type).
    # Per HUD FAQ, if there are multiple such parents, all should be counted.

    context 'when HoH is 22, with a child (single adult qualifying household)' do
      before do
        household_id = 'py_hoh_for_youth_single_adult'
        hoh_client = create_client_with_warehouse_link(uid: 'py_hfy_hoh22_single', dob: dob_youth_22)
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_hoh, household_id: household_id)

        child_client = create_client_with_warehouse_link(uid: 'py_hfy_child5_single', dob: dob_child_5)
        create_enrollment(client: child_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_child, household_id: household_id)
      end

      it 'counts the HoH' do
        report = run_report(questions: [question])
        hoh_for_youth_count = report.answer(question: question, cell: 'B4')
        expect(hoh_for_youth_count.value).to eq(1)
      end
    end

    context 'when HoH is 23, spouse is 22, with a child (qualifying PYH with two parents)' do
      before do
        household_id = 'py_hoh_for_youth_multi_adult_spouse'
        hoh_client = create_client_with_warehouse_link(uid: 'py_hfy_hoh23_multi_spouse', dob: pit_date - 23.years)
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_hoh, household_id: household_id)

        spouse_client = create_client_with_warehouse_link(uid: 'py_hfy_spouse22_multi', dob: dob_youth_22)
        create_enrollment(client: spouse_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_spouse, household_id: household_id)

        child_client = create_client_with_warehouse_link(uid: 'py_hfy_child_for_multi_spouse', dob: dob_child_5)
        create_enrollment(client: child_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_child, household_id: household_id)
      end

      it 'counts both HoH and spouse' do
        report = run_report(questions: [question])
        hoh_for_youth_count = report.answer(question: question, cell: 'B4')
        expect(hoh_for_youth_count.value).to eq(2)
      end
    end

    context 'when household has adult >= 25 (not a qualifying PYH)' do
      before do
        household_id = 'py_hoh_for_youth_invalid_max_age'
        hoh_client = create_client_with_warehouse_link(uid: 'py_hfy_hoh22_old_adult', dob: dob_youth_22)
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_hoh, household_id: household_id)

        child_client = create_client_with_warehouse_link(uid: 'py_hfy_child_old_adult', dob: dob_child_5)
        create_enrollment(client: child_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_child, household_id: household_id)

        older_adult = create_client_with_warehouse_link(uid: 'py_hfy_adult25', dob: dob_adult_25)
        create_enrollment(client: older_adult, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_other_adult, household_id: household_id)
      end

      it 'counts 0 because household is filtered out by max_age' do
        report = run_report(questions: [question])
        hoh_for_youth_count = report.answer(question: question, cell: 'B4')
        expect(hoh_for_youth_count.value).to eq(0)
      end
    end

    context 'when HoH is 17, spouse is 19, with a child (qualifying PYH with mixed-age parents <25)' do
      let(:dob_youth_19) { pit_date - 19.years } # Helper for this context

      before do
        household_id = 'py_hoh_for_youth_mixed_age_parents'
        hoh_client = create_client_with_warehouse_link(uid: 'py_hfy_hoh17_mixed', dob: dob_youth_17)
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_hoh, household_id: household_id)

        spouse_client = create_client_with_warehouse_link(uid: 'py_hfy_spouse19_mixed', dob: dob_youth_19)
        create_enrollment(client: spouse_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_spouse, household_id: household_id)

        child_client = create_client_with_warehouse_link(uid: 'py_hfy_child_mixed_parents', dob: dob_child_5)
        create_enrollment(client: child_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_child, household_id: household_id)
      end

      it 'counts both HoH (<18) and spouse (18-24)' do
        report = run_report(questions: [question])
        hoh_for_youth_count = report.answer(question: question, cell: 'B4')
        expect(hoh_for_youth_count.value).to eq(2)
      end
    end
  end

  describe 'Children in Parenting Youth Households' do
    # This tests :children_of_youth_parents (B5)
    # Counts children in a qualifying PYH (all members < 25, adults_and_children type, at least one youth parent).
    # Number of parents (1 or 2) should not affect child count if HH qualifies.

    context 'when HoH is 22, with one child aged 5 (single adult qualifying household)' do
      before do
        household_id = 'py_children_of_youth_single_adult_1'
        hoh_client = create_client_with_warehouse_link(uid: 'py_coyp_hoh22_single', dob: dob_youth_22)
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_hoh, household_id: household_id)

        child_client = create_client_with_warehouse_link(uid: 'py_coyp_child5_single', dob: dob_child_5)
        create_enrollment(client: child_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_child, household_id: household_id)
      end

      it 'counts the child' do
        report = run_report(questions: [question])
        children_in_py_hh_count = report.answer(question: question, cell: 'B5')
        expect(children_in_py_hh_count.value).to eq(1)
      end
    end

    context 'when HoH (22) and Spouse (20) are present with one child (qualifying PYH with two parents)' do
      before do
        household_id = 'py_children_of_youth_multi_adult'
        hoh_client = create_client_with_warehouse_link(uid: 'py_coyp_hoh22_multi', dob: dob_youth_22)
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_hoh, household_id: household_id)

        spouse_client = create_client_with_warehouse_link(uid: 'py_coyp_spouse20_multi', dob: pit_date - 20.years)
        create_enrollment(client: spouse_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_spouse, household_id: household_id)

        child_client = create_client_with_warehouse_link(uid: 'py_coyp_child3_multi', dob: pit_date - 3.years)
        create_enrollment(client: child_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_child, household_id: household_id)
      end

      it 'counts the child (household is a valid PYH)' do
        report = run_report(questions: [question])
        children_in_py_hh_count = report.answer(question: question, cell: 'B5')
        expect(children_in_py_hh_count.value).to eq(1)
      end
    end

    context 'when household has adult >= 25 (not a qualifying PYH)' do
      before do
        household_id = 'py_children_of_youth_invalid_max_age'
        hoh_client = create_client_with_warehouse_link(uid: 'py_coyp_hoh22_old_adult', dob: dob_youth_22)
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_hoh, household_id: household_id)

        child_client = create_client_with_warehouse_link(uid: 'py_coyp_child_old_adult', dob: dob_child_5)
        create_enrollment(client: child_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_child, household_id: household_id)

        older_adult = create_client_with_warehouse_link(uid: 'py_coyp_adult25', dob: dob_adult_25)
        create_enrollment(client: older_adult, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_other_adult, household_id: household_id)
      end

      it 'counts 0 children because household is filtered out by max_age' do
        report = run_report(questions: [question])
        children_in_py_hh_count = report.answer(question: question, cell: 'B5')
        expect(children_in_py_hh_count.value).to eq(0)
      end
    end
  end

  describe 'Children with Parents 18-24' do
    # This tests :children_of_18_to_24_parents (B9).
    # Counts children in a qualifying PYH where AT LEAST ONE parent is 18-24.
    # The household must be a PYH (all members < 25, adults & children, at least one youth parent).

    context 'when HoH is 22, with one child aged 5 (single adult qualifying PYH)' do
      before do
        household_id = 'py_children_p1824_single_adult_1'
        hoh_client = create_client_with_warehouse_link(uid: 'py_c1824p_hoh22_single', dob: dob_youth_22)
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_hoh, household_id: household_id)

        child_client = create_client_with_warehouse_link(uid: 'py_c1824p_child5_single', dob: dob_child_5)
        create_enrollment(client: child_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_child, household_id: household_id)
      end

      it 'counts the child' do
        report = run_report(questions: [question])
        children_count = report.answer(question: question, cell: 'B9')
        expect(children_count.value).to eq(1)
      end
    end

    context 'when HoH is 18, with two children (single adult qualifying PYH)' do
      before do
        household_id = 'py_children_p1824_single_adult_2'
        hoh_client = create_client_with_warehouse_link(uid: 'py_c1824p_hoh18_single', dob: dob_youth_18)
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_hoh, household_id: household_id)

        child1 = create_client_with_warehouse_link(uid: 'py_c1824p_child2_single', dob: pit_date - 2.years)
        create_enrollment(client: child1, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_child, household_id: household_id)

        child2 = create_client_with_warehouse_link(uid: 'py_c1824p_child4_single', dob: pit_date - 4.years)
        create_enrollment(client: child2, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_child, household_id: household_id)
      end

      it 'counts both children' do
        report = run_report(questions: [question])
        children_count = report.answer(question: question, cell: 'B9')
        expect(children_count.value).to eq(2)
      end
    end

    context 'when HoH is 17 (parent <18), with a child (HoH <18, no 18+ adult, HH likely filtered)' do
      before do
        household_id = 'py_children_p1824_hoh17_no_18plus'
        hoh_client = create_client_with_warehouse_link(uid: 'py_c1824p_hoh17_no_18plus', dob: dob_youth_17)
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_hoh, household_id: household_id)

        child_client = create_client_with_warehouse_link(uid: 'py_c1824p_child_hoh17_no_18plus', dob: dob_child_5)
        create_enrollment(client: child_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_child, household_id: household_id)
      end

      it 'counts 0 children as HH likely filtered (or parent wrong age for B9)' do
        report = run_report(questions: [question])
        children_count = report.answer(question: question, cell: 'B9')
        expect(children_count.value).to eq(0)
      end
    end

    context 'when HoH (22) and Spouse (20) are present with one child (qualifying PYH with two parents 18-24)' do
      before do
        household_id = 'py_children_p1824_multi_adult'
        hoh_client = create_client_with_warehouse_link(uid: 'py_c1824p_hoh22_multi', dob: dob_youth_22)
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_hoh, household_id: household_id)

        spouse_client = create_client_with_warehouse_link(uid: 'py_c1824p_spouse20_multi', dob: pit_date - 20.years)
        create_enrollment(client: spouse_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_spouse, household_id: household_id)

        child_client = create_client_with_warehouse_link(uid: 'py_c1824p_child3_multi', dob: pit_date - 3.years)
        create_enrollment(client: child_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_child, household_id: household_id)
      end

      it 'counts the child (household is a valid PYH with 18-24 parent(s))' do
        report = run_report(questions: [question])
        children_count = report.answer(question: question, cell: 'B9')
        expect(children_count.value).to eq(1)
      end
    end
  end

  describe 'Children with Parents <18' do
    # This tests :children_of_0_to_18_parents (B7).
    # Counts children in a qualifying PYH where AT LEAST ONE parent is <18.
    # The household must be a PYH (all members < 25, adults & children, at least one youth parent).

    context 'when HoH is 18 (parent 18-24), with a child (qualifying PYH)' do
      before do
        household_id = 'py_children_p_u18_hoh_too_old_single_adult'
        hoh_client = create_client_with_warehouse_link(uid: 'py_cu18p_hoh18_single', dob: dob_youth_18)
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_hoh, household_id: household_id)

        child_client = create_client_with_warehouse_link(uid: 'py_cu18p_child_for_hoh18_single', dob: dob_child_5)
        create_enrollment(client: child_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_child, household_id: household_id)
      end

      it 'counts 0 children for this specific sub-calculation (parent wrong age for B7)' do
        report = run_report(questions: [question])
        children_count = report.answer(question: question, cell: 'B7')
        expect(children_count.value).to eq(0)
      end
    end
  end

  # Tests for parenting youth counts
end
