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
        adult_question = HudPit::Generators::Pit::Fy2025::AdultAndChild::QUESTION_NUMBER
        report = run_report(questions: [question, adult_question])
        parenting_youth_18_24_count = report_value(report, question: question, row: :parenting_youth_18_24)
        expect(parenting_youth_18_24_count).to eq(0)

        # Verify household is counted in adult-only category
        adult_only_count = report_value(report, question: adult_question, row: :total_persons)
        expect(adult_only_count).to eq(3)
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

    context 'when HoH is >18 with a child, and another non-parenting youth adult (18-24) is present' do
      let(:adult_child_question) { HudPit::Generators::Pit::Fy2025::AdultAndChild::QUESTION_NUMBER }
      before do
        household_id = 'py_youth_hoh_18_24_with_other_adult_and_child'
        hoh_client = create_client_with_warehouse_link(uid: 'py_hoh_22_no_child', dob: dob_youth_17)
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_hoh, household_id: household_id)

        other_youth_adult = create_client_with_warehouse_link(uid: 'py_other_youth_no_child_adult', dob: dob_youth_18)
        create_enrollment(client: other_youth_adult, project: es_project, entry_date: pit_date, relationship_to_ho_h: rel_other_adult, household_id: household_id)

        child_client = create_client_with_warehouse_link(uid: 'py_child_for_hoh_with_other_adult', dob: dob_child_5)
        create_enrollment(
          client: child_client,
          project: es_project,
          entry_date: pit_date,
          relationship_to_ho_h: rel_child,
          household_id: household_id,
        )
      end

      it 'counts only the HoH as a parenting youth, not the other youth adult' do
        report = run_report(questions: [question, adult_child_question])

        expect(
          report_value(report, question: question, row: :total_parents),
        ).to eq(1)
        expect(
          report_value(report, question: question, row: :parenting_youth_under_18),
        ).to eq(1)
        expect(
          report_value(report, question: question, row: :parenting_youth_18_24),
        ).to eq(0)
        expect(
          report_value(report, question: question, row: :children_with_parents_under_18),
        ).to eq(1)
        expect(
          report_value(report, question: question, row: :children_with_parents_18_to_24),
        ).to eq(0)
      end
    end

    context 'when HoH (18-24) has a child enrolled AFTER the PIT date' do
      let(:adult_question) { HudPit::Generators::Pit::Fy2025::Adults::QUESTION_NUMBER }
      before do
        household_id = 'py_hoh_18_24_child_enrolled_late'
        hoh_client = create_client_with_warehouse_link(uid: 'py_hoh_20_child_late', dob: pit_date - 20.years)
        create_enrollment(
          client: hoh_client,
          project: es_project,
          entry_date: pit_date - 1.day, # HoH present on PIT date
          relationship_to_ho_h: rel_hoh,
          household_id: household_id,
        )

        # Child enrolled *after* PIT date
        child_client = create_client_with_warehouse_link(uid: 'py_child_late_enrollment', dob: dob_child_5)
        create_enrollment(
          client: child_client,
          project: es_project,
          entry_date: pit_date + 1.day, # Enrolled after PIT date
          relationship_to_ho_h: rel_child,
          household_id: household_id,
        )
      end

      it 'does not count HoH as parenting youth, HoH is in adult-only household' do
        report = run_report(questions: [question, adult_question])

        # Verify HoH is NOT counted as a parenting youth
        total_parent_count = report_value(report, question: question, row: :total_parents)
        expect(total_parent_count).to eq(0)

        # Verify HoH is counted in the adult-only household category
        adult_only_persons_count = report_value(report, question: adult_question, row: :total_persons)
        expect(adult_only_persons_count).to eq(1) # Only the HoH
      end
    end

    context 'when HoH (18yo) is enrolled with a child, but child exits BEFORE PIT date' do
      let(:adult_question) { HudPit::Generators::Pit::Fy2025::Adults::QUESTION_NUMBER }
      before do
        household_id = 'py_hoh18_child_exited_early'

        # HoH, 18 years old, present on PIT date
        hoh_client = create_client_with_warehouse_link(uid: 'py_hoh18_child_exited', dob: dob_youth_18)
        create_enrollment(
          client: hoh_client,
          project: es_project,
          entry_date: pit_date - 10.days, # Enrolled before PIT date
          exit_date: nil, # Still present
          relationship_to_ho_h: rel_hoh,
          household_id: household_id,
        )

        # Child, enrolled with HoH but exited BEFORE PIT date
        child_client = create_client_with_warehouse_link(uid: 'py_child_exited_early', dob: dob_child_5)
        create_enrollment(
          client: child_client,
          project: es_project,
          entry_date: pit_date - 10.days, # Enrolled with HoH
          exit_date: pit_date - 1.day, # Exited before PIT date
          relationship_to_ho_h: rel_child,
          household_id: household_id,
        )
      end

      it 'counts HoH in adult-only household, not as parenting youth' do
        report = run_report(questions: [question, adult_question])

        # Verify HoH is NOT counted as a parenting youth
        expect(report_value(report, question: question, row: :total_parents)).to eq(0)
        expect(report_value(report, question: question, row: :parenting_youth_18_24)).to eq(0)
        expect(report_value(report, question: question, row: :parenting_youth_under_18)).to eq(0)

        # Verify no children are counted in parenting youth categories
        expect(report_value(report, question: question, row: :total_children)).to eq(0)
        expect(report_value(report, question: question, row: :children_with_parents_under_18)).to eq(0)
        expect(report_value(report, question: question, row: :children_with_parents_18_to_24)).to eq(0)

        # Verify HoH is counted in the adult-only household category
        expect(report_value(report, question: adult_question, row: :total_persons)).to eq(1) # Only the HoH
        expect(report_value(report, question: adult_question, row: :persons_18_24)).to eq(1) # HoH is 18
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

    context 'when HoH (<18) has a child, and an older spouse (>18) is enrolled AFTER PIT date' do
      before do
        household_id = 'py_child_u18p_older_spouse_late'
        # Minor HoH, present on PIT date
        hoh_client = create_client_with_warehouse_link(uid: 'py_cu18p_hoh17_spouse_late', dob: dob_youth_17)
        create_enrollment(
          client: hoh_client,
          project: es_project,
          entry_date: pit_date,
          relationship_to_ho_h: rel_hoh,
          household_id: household_id,
        )

        # Child, present on PIT date
        child_client = create_client_with_warehouse_link(uid: 'py_cu18p_child_spouse_late', dob: dob_child_5)
        create_enrollment(
          client: child_client,
          project: es_project,
          entry_date: pit_date,
          relationship_to_ho_h: rel_child,
          household_id: household_id,
        )

        # Older spouse, enrolled AFTER PIT date
        spouse_client = create_client_with_warehouse_link(uid: 'py_cu18p_spouse22_late', dob: dob_youth_22)
        create_enrollment(
          client: spouse_client,
          project: es_project,
          entry_date: pit_date + 1.day, # Enrolled after PIT date
          relationship_to_ho_h: rel_spouse,
          household_id: household_id,
        )
      end

      it 'counts child with <18 parent, and late spouse does not affect parent age bucket for child' do
        report = run_report(questions: [question])

        # Verify child is counted with the <18 parent
        children_with_under_18_parents = report_value(report, question: question, row: :children_with_parents_under_18)
        expect(children_with_under_18_parents).to eq(1)

        # Verify child is NOT counted with 18-24 parents (due to late spouse)
        children_with_18_to_24_parents = report_value(report, question: question, row: :children_with_parents_18_to_24)
        expect(children_with_18_to_24_parents).to eq(0)

        # Verify the minor HoH is counted as a parenting youth < 18
        parenting_youth_under_18 = report_value(report, question: question, row: :parenting_youth_under_18)
        expect(parenting_youth_under_18).to eq(1)

        # Verify the older, late-enrolled spouse is NOT counted as parenting youth 18-24
        parenting_youth_18_24 = report_value(report, question: question, row: :parenting_youth_18_24)
        expect(parenting_youth_18_24).to eq(0)

        # Verify total parents counted is 1 (only the HoH on PIT date)
        total_parents = report_value(report, question: question, row: :total_parents)
        expect(total_parents).to eq(1)
      end
    end

    context 'when HoH (<18) has a child, and an older spouse (>18) was enrolled but EXITED BEFORE PIT date' do
      before do
        household_id = 'py_child_u18p_older_spouse_exited_early'
        # Minor HoH, present on PIT date
        hoh_client = create_client_with_warehouse_link(uid: 'py_cu18p_hoh17_spouse_early_exit', dob: dob_youth_17)
        create_enrollment(
          client: hoh_client,
          project: es_project,
          entry_date: pit_date - 5.days, # Present before and on PIT date
          exit_date: nil,
          relationship_to_ho_h: rel_hoh,
          household_id: household_id,
        )

        # Child, present on PIT date
        child_client = create_client_with_warehouse_link(uid: 'py_cu18p_child_spouse_early_exit', dob: dob_child_5)
        create_enrollment(
          client: child_client,
          project: es_project,
          entry_date: pit_date - 5.days, # Present before and on PIT date
          exit_date: nil,
          relationship_to_ho_h: rel_child,
          household_id: household_id,
        )

        # Older spouse, enrolled AND exited BEFORE PIT date
        spouse_client = create_client_with_warehouse_link(uid: 'py_cu18p_spouse22_early_exit', dob: dob_youth_22)
        create_enrollment(
          client: spouse_client,
          project: es_project,
          entry_date: pit_date - 5.days, # Enrolled before PIT date
          exit_date: pit_date - 1.day,   # Exited before PIT date
          relationship_to_ho_h: rel_spouse,
          household_id: household_id,
        )
      end

      it 'counts child with <18 parent; early-exiting spouse does not affect parent age bucket for child' do
        report = run_report(questions: [question])

        # Verify child is counted with the <18 parent
        children_with_under_18_parents = report_value(report, question: question, row: :children_with_parents_under_18)
        expect(children_with_under_18_parents).to eq(1)

        # Verify child is NOT counted with 18-24 parents
        children_with_18_to_24_parents = report_value(report, question: question, row: :children_with_parents_18_to_24)
        expect(children_with_18_to_24_parents).to eq(0)

        # Verify the minor HoH is counted as a parenting youth < 18
        parenting_youth_under_18 = report_value(report, question: question, row: :parenting_youth_under_18)
        expect(parenting_youth_under_18).to eq(1)

        # Verify the older, early-exiting spouse is NOT counted as parenting youth 18-24
        parenting_youth_18_24 = report_value(report, question: question, row: :parenting_youth_18_24)
        expect(parenting_youth_18_24).to eq(0)

        # Verify total parents counted is 1 (only the HoH on PIT date)
        total_parents = report_value(report, question: question, row: :total_parents)
        expect(total_parents).to eq(1)
      end
    end
  end

  describe 'Parenting Youth (Youth Parents Only)' do
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

      it 'counts both HoH (<18) and spouse (18-24) and correctly categorizes children' do
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

        total_children_count = report_value(report, question: question, row: :total_children) # B5
        expect(total_children_count).to eq(1)
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
