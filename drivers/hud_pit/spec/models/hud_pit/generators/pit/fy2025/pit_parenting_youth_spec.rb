# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
        parenting_youth_18_24_count = report_value(report, question: question, row: :parenting_youth_18_24)
        expect(parenting_youth_18_24_count).to eq(1)
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
        parenting_youth_18_24_count = report_value(report, question: question, row: :parenting_youth_18_24)
        expect(parenting_youth_18_24_count).to eq(2)
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

      it 'is not counted as parenting youth and household is counted in adult-only category' do
        adult_question = HudPit::Generators::Pit::Fy2025::Adults::QUESTION_NUMBER
        report = run_report(questions: [question, adult_question])
        parent_count = report_value(report, question: question, row: :total_parents)
        expect(parent_count).to eq(0)

        # Verify household is counted in adult-only category
        adult_only_count = report_value(report, question: adult_question, row: :total_persons)
        expect(adult_only_count).to eq(2)
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
        parenting_youth_18_24_count = report_value(report, question: question, row: :parenting_youth_18_24)
        expect(parenting_youth_18_24_count).to eq(0)
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

      it 'counts 0 for 18-24 PY, but HoH in <18 PY and child in its category' do
        report = run_report(questions: [question])
        parenting_youth_18_24_count = report_value(report, question: question, row: :parenting_youth_18_24)
        expect(parenting_youth_18_24_count).to eq(0)

        # Verify HoH (<18) is counted in the <18 PY category
        parenting_youth_under_18_count = report_value(report, question: question, row: :parenting_youth_under_18)
        expect(parenting_youth_under_18_count).to eq(1)

        # Verify child is counted with <18 PY
        children_with_parents_under_18_count = report_value(report, question: question, row: :children_with_parents_under_18)
        expect(children_with_parents_under_18_count).to eq(1)
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

      it 'counts HoH as Number of parenting youth (under age 18)' do
        report = run_report(questions: [question])
        parenting_youth_under_18_count = report_value(report, question: question, row: :parenting_youth_under_18)
        expect(parenting_youth_under_18_count).to eq(1)
        children_in_parenting_youth_under_18_count = report_value(report, question: question, row: :children_with_parents_under_18)
        expect(children_in_parenting_youth_under_18_count).to eq(1)
      end
    end

    context 'when HoH (<18) and Spouse (<18) are present with a child (no 18+ adult in HH)' do
      before do
        household_id = 'py_multi_adult_under_18_no_18plus_adult'
        # HoH, age 17
        create_enrollment(
          client: create_client_with_warehouse_link(uid: 'py_hoh_17_multi_no_18plus', dob: dob_youth_17),
          project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_hoh, household_id: household_id
        )
        # Spouse, age 16
        create_enrollment(
          client: create_client_with_warehouse_link(uid: 'py_spouse_16_multi_no_18plus', dob: pit_date - 16.years),
          project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_spouse, household_id: household_id
        )
        # Child 1, age 2
        create_enrollment(
          client: create_client_with_warehouse_link(uid: 'py_child_2_for_multi_no_18plus', dob: pit_date - 2.years),
          project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_child, household_id: household_id
        )
        # Child 2, age 4
        create_enrollment(
          client: create_client_with_warehouse_link(uid: 'py_child_4_for_multi_no_18plus', dob: pit_date - 4.years),
          project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_child, household_id: household_id
        )
      end

      it 'counts HoH and spouse as Number of parenting youth (under age 18)' do
        report = run_report(questions: [question])
        parenting_youth_under_18_count = report_value(report, question: question, row: :parenting_youth_under_18)
        expect(parenting_youth_under_18_count).to eq(2)
        children_in_parenting_youth_under_18_count = report_value(report, question: question, row: :children_with_parents_under_18)
        expect(children_in_parenting_youth_under_18_count).to eq(2)
      end
    end

    context 'when HoH is <18, and no other child present (household is child_only)' do
      before do
        household_id = 'py_child_hoh_under_18_no_child'
        hoh_client = create_client_with_warehouse_link(uid: 'py_hoh_17_no_child_u18', dob: dob_youth_17)
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_hoh, household_id: household_id)
      end

      it 'counts 0 for <18 PY, and household counted in child-only category' do
        child_question = HudPit::Generators::Pit::Fy2025::Children::QUESTION_NUMBER
        report = run_report(questions: [question, child_question])
        parenting_youth_under_18_count = report_value(report, question: question, row: :parenting_youth_under_18)
        expect(parenting_youth_under_18_count).to eq(0)

        # Verify household is counted in child-only category (HoH is the only member)
        child_only_count = report_value(report, question: child_question, row: :total_persons)
        expect(child_only_count).to eq(1)
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

      it 'counts 0 for <18 PY due to max_age, but HH counted in general Adults+Children' do
        adult_child_question = HudPit::Generators::Pit::Fy2025::AdultAndChild::QUESTION_NUMBER
        report = run_report(questions: [question, adult_child_question])
        parenting_youth_under_18_count = report_value(report, question: question, row: :parenting_youth_under_18)
        expect(parenting_youth_under_18_count).to eq(0)

        # Verify household is counted in the general Households with Adults and Children category
        adult_and_child_hh_count = report_value(report, question: adult_child_question, row: :total_households)
        expect(adult_and_child_hh_count).to eq(1)
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

      it 'counts 0 for <18 PY, but HoH in 18-24 PY and child in its category' do
        report = run_report(questions: [question])
        parenting_youth_under_18_count = report_value(report, question: question, row: :parenting_youth_under_18)
        expect(parenting_youth_under_18_count).to eq(0)

        # Verify HoH (18-24) is counted in the 18-24 PY category
        parenting_youth_18_24_count = report_value(report, question: question, row: :parenting_youth_18_24)
        expect(parenting_youth_18_24_count).to eq(1)

        # Verify child is counted with 18-24 PY
        children_with_parents_18_to_24_count = report_value(report, question: question, row: :children_with_parents_18_to_24)
        expect(children_with_parents_18_to_24_count).to eq(1)
      end
    end
  end

  describe 'Parenting Youth (Youth Parents Only)' do
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
        hoh_for_youth_count = report_value(report, question: question, row: :total_parents)
        expect(hoh_for_youth_count).to eq(1)
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
        hoh_for_youth_count = report_value(report, question: question, row: :total_parents)
        expect(hoh_for_youth_count).to eq(2)
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
        hoh_for_youth_count = report_value(report, question: question, row: :total_parents)
        expect(hoh_for_youth_count).to eq(0)
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
        hoh_for_youth_count = report_value(report, question: question, row: :total_parents)
        expect(hoh_for_youth_count).to eq(2)

        # Children should be counted based on the household's max_age (which is 19 here, due to the spouse)
        # So, they fall under 'Children with Parents 18-24' (B9)
        # and NOT under 'Children with Parents <18' (B7)
        children_with_parents_under_18_count = report_value(report, question: question, row: :children_with_parents_under_18)
        expect(children_with_parents_under_18_count).to eq(0)

        children_with_parents_18_to_24_count = report_value(report, question: question, row: :children_with_parents_18_to_24)
        expect(children_with_parents_18_to_24_count).to eq(1)
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
        children_in_py_hh_count = report_value(report, question: question, row: :total_children)
        expect(children_in_py_hh_count).to eq(1)
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
        children_in_py_hh_count = report_value(report, question: question, row: :total_children)
        expect(children_in_py_hh_count).to eq(1)
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
        children_in_py_hh_count = report_value(report, question: question, row: :total_children)
        expect(children_in_py_hh_count).to eq(0)
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
        children_count = report_value(report, question: question, row: :children_with_parents_18_to_24)
        expect(children_count).to eq(1)
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
        children_count = report_value(report, question: question, row: :children_with_parents_18_to_24)
        expect(children_count).to eq(2)
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

      it 'counts 0 children for B9, but parent in <18 PY and child in its category' do
        report = run_report(questions: [question])
        children_with_parents_18_to_24_count = report_value(report, question: question, row: :children_with_parents_18_to_24)
        expect(children_with_parents_18_to_24_count).to eq(0)

        # Verify parent (<18) is counted in the <18 PY category
        parenting_youth_under_18_count = report_value(report, question: question, row: :parenting_youth_under_18)
        expect(parenting_youth_under_18_count).to eq(1)

        # Verify child is counted with <18 PY
        children_with_parents_under_18_count = report_value(report, question: question, row: :children_with_parents_under_18)
        expect(children_with_parents_under_18_count).to eq(1)
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
        children_count = report_value(report, question: question, row: :children_with_parents_18_to_24)
        expect(children_count).to eq(1)
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

      it 'counts 0 children for B7, but parent in 18-24 PY and child in its category' do
        report = run_report(questions: [question])
        children_with_parents_under_18_count = report_value(report, question: question, row: :children_with_parents_under_18)
        expect(children_with_parents_under_18_count).to eq(0)

        # Verify parent (18-24) is counted in the 18-24 PY category
        parenting_youth_18_24_count = report_value(report, question: question, row: :parenting_youth_18_24)
        expect(parenting_youth_18_24_count).to eq(1)

        # Verify child is counted with 18-24 PY
        children_with_parents_18_to_24_count = report_value(report, question: question, row: :children_with_parents_18_to_24)
        expect(children_with_parents_18_to_24_count).to eq(1)
      end
    end
  end

  # Tests for parenting youth counts
end
