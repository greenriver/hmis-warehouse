# frozen_string_literal: true

require 'rails_helper'
require_relative 'hud_pit_context'

RSpec.describe 'PIT Basic Counts', type: :model do
  include_context 'HUD pit context'

  describe 'Household and Person Counts' do
    let(:es_project) { create_project(project_type: 0) } # ES-EE

    context 'when there is one household with one adult' do
      let(:question) { HudPit::Generators::Pit::Fy2025::Adults::QUESTION_NUMBER }
      before do
        household_id = 'hh_total_households_1'
        hoh_client = create_client_with_warehouse_link
        create_enrollment(
          client: hoh_client,
          project: es_project,
          entry_date: pit_date,
          relationship_to_ho_h: 1, # Head of household
          household_id: household_id,
        )
      end

      it 'counts one household' do
        # This setup technically doesn't fit "Adult & Child" question criteria (needs a child)
        # but the :households sub_calculation itself should still count any HoH.
        # We will use a more appropriate question type if this fails or for more precise tests.
        report = run_report(questions: [question])

        # Total Number of Households is B2 for AdultAndChild question
        total_households = report.answer(question: question, cell: 'B2')
        expect(total_households.value).to eq(1)
      end
    end

    context 'when there are two distinct households' do
      let(:question) { HudPit::Generators::Pit::Fy2025::Adults::QUESTION_NUMBER }
      before do
        # Household 1
        household_id_1 = 'hh_total_households_2a'
        hoh_client_1 = create_client_with_warehouse_link(uid: 'client_hoh_2a')
        create_enrollment(
          client: hoh_client_1,
          project: es_project,
          entry_date: pit_date,
          relationship_to_ho_h: 1,
          household_id: household_id_1,
        )

        # Household 2
        household_id_2 = 'hh_total_households_2b'
        hoh_client_2 = create_client_with_warehouse_link(uid: 'client_hoh_2b')
        create_enrollment(
          client: hoh_client_2,
          project: es_project,
          entry_date: pit_date,
          relationship_to_ho_h: 1,
          household_id: household_id_2,
        )
      end

      it 'counts two households' do
        report = run_report(questions: [question])
        total_households = report.answer(question: question, cell: 'B2')
        expect(total_households.value).to eq(2)
      end
    end

    context 'when a household has multiple members' do
      let(:adult_dob) { pit_date - 30.years }
      let(:child_dob_under_18) { pit_date - 10.years }
      let(:question) { HudPit::Generators::Pit::Fy2025::AdultAndChild::QUESTION_NUMBER }

      before do
        household_id = 'hh_total_persons_1'

        # Head of Household
        hoh_client = create_client_with_warehouse_link(uid: 'client_tp_hoh', dob: adult_dob)
        create_enrollment(
          client: hoh_client,
          project: es_project,
          entry_date: pit_date,
          relationship_to_ho_h: 1,
          household_id: household_id,
        )

        # Adult member
        adult_member = create_client_with_warehouse_link(uid: 'client_tp_adult', dob: adult_dob) # dob ensuring adult
        create_enrollment(
          client: adult_member,
          project: es_project,
          entry_date: pit_date,
          relationship_to_ho_h: 2, # Adult other member
          household_id: household_id,
        )

        # Child member
        child_member = create_client_with_warehouse_link(uid: 'client_tp_child', dob: child_dob_under_18) # dob ensuring child
        create_enrollment(
          client: child_member,
          project: es_project,
          entry_date: pit_date,
          relationship_to_ho_h: 3, # Child
          household_id: household_id,
        )
      end

      it 'counts all persons in the household' do
        report = run_report(questions: [question])

        # Total Number of Persons is B3 for AdultAndChild question
        total_persons = report.answer(question: question, cell: 'B3')
        expect(total_persons.value).to eq(3)
      end
    end

    context 'when there are multiple households with multiple members' do
      let(:question) { HudPit::Generators::Pit::Fy2025::AdultAndChild::QUESTION_NUMBER }
      let(:adult_dob) { pit_date - 30.years }
      let(:child_dob_under_18) { pit_date - 10.years }

      before do
        # Household 1 (1 HoH, 1 Child) -> 2 persons
        hh_id1 = 'hh_total_persons_2a'
        hoh1 = create_client_with_warehouse_link(uid: 'client_tp_2a_hoh', dob: adult_dob)
        create_enrollment(client: hoh1, project: es_project, entry_date: pit_date, relationship_to_ho_h: 1, household_id: hh_id1)
        child1 = create_client_with_warehouse_link(uid: 'client_tp_2a_child', dob: child_dob_under_18)
        create_enrollment(client: child1, project: es_project, entry_date: pit_date, relationship_to_ho_h: 3, household_id: hh_id1)

        # Household 2 (1 HoH) -> 1 person
        hh_id2 = 'hh_total_persons_2b'
        hoh2 = create_client_with_warehouse_link(uid: 'client_tp_2b_hoh', dob: adult_dob)
        create_enrollment(client: hoh2, project: es_project, entry_date: pit_date, relationship_to_ho_h: 1, household_id: hh_id2)
        child2 = create_client_with_warehouse_link(uid: 'client_tp_2b_child', dob: child_dob_under_18)
        create_enrollment(client: child2, project: es_project, entry_date: pit_date, relationship_to_ho_h: 3, household_id: hh_id2)
      end

      it 'counts total persons across all households' do
        report = run_report(questions: [question])
        total_persons = report.answer(question: question, cell: 'B3')
        expect(total_persons.value).to eq(4) # 2 from hh1 + 2 from hh2
      end
    end
  end

  describe 'Age-based Counts' do
    let(:question) { HudPit::Generators::Pit::Fy2025::AdultAndChild::QUESTION_NUMBER }
    let(:es_project) { create_project(project_type: 0) } # ES-EE

    # Define Dobs relative to pit_date for consistent age calculation
    let(:dob_child_5) { pit_date - 5.years } # Exactly 5 years old
    let(:dob_child_17) { pit_date - 17.years } # Exactly 17 years old
    let(:dob_adult_18) { pit_date - 18.years } # Exactly 18 years old
    let(:dob_adult_25) { pit_date - 25.years } # Exactly 25 years old

    context 'for Persons Under 18 (Children)' do
      before do
        household_id = 'hh_children_1'
        # Household with one HoH (adult) and two children (5 and 17 years old)
        hoh_client = create_client_with_warehouse_link(uid: 'client_child_hoh', dob: dob_adult_25)
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: 1, household_id: household_id)

        child_1 = create_client_with_warehouse_link(uid: 'client_child_c1', dob: dob_child_5)
        create_enrollment(client: child_1, project: es_project, entry_date: pit_date, relationship_to_ho_h: 3, household_id: household_id)

        child_2 = create_client_with_warehouse_link(uid: 'client_child_c2', dob: dob_child_17)
        create_enrollment(client: child_2, project: es_project, entry_date: pit_date, relationship_to_ho_h: 3, household_id: household_id)

        # Add an adult who is not a child to ensure they are not counted
        adult_member = create_client_with_warehouse_link(uid: 'client_child_adult', dob: dob_adult_18)
        create_enrollment(client: adult_member, project: es_project, entry_date: pit_date, relationship_to_ho_h: 2, household_id: household_id)
      end

      it 'counts only persons under 18' do
        report = run_report(questions: [question])
        # Number of Persons (under age 18) is B4 for AdultAndChild question
        children_count = report.answer(question: question, cell: 'B4')
        expect(children_count.value).to eq(2)
      end
    end

    context 'when there are no children' do
      before do
        household_id = 'hh_no_children_1'
        hoh_client = create_client_with_warehouse_link(uid: 'client_nochild_hoh', dob: dob_adult_25)
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: 1, household_id: household_id)

        adult_member = create_client_with_warehouse_link(uid: 'client_nochild_adult', dob: dob_adult_18)
        create_enrollment(client: adult_member, project: es_project, entry_date: pit_date, relationship_to_ho_h: 2, household_id: household_id)
      end

      it 'counts zero children' do
        report = run_report(questions: [question])
        children_count = report.answer(question: question, cell: 'B4')
        expect(children_count.value).to eq(0)
      end
    end

    context 'for Persons 18-24 (Youth)' do
      let(:question) { HudPit::Generators::Pit::Fy2025::AdultAndChild::QUESTION_NUMBER }
      let(:dob_youth_18) { pit_date - 18.years } # Exactly 18
      let(:dob_youth_20) { pit_date - 20.years } # Exactly 20
      let(:dob_youth_24) { pit_date - 24.years } # Exactly 24
      let(:dob_adult_25) { pit_date - 25.years } # Exactly 25 (not youth)
      let(:dob_child_17) { pit_date - 17.years } # Exactly 17 (not youth)

      before do
        household_id = 'hh_youth_1'
        # Household with one HoH (adult) and three youth (18, 20, 24 years old)
        hoh_client = create_client_with_warehouse_link(uid: 'client_youth_hoh', dob: dob_adult_25) # Non-youth HoH
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: 1, household_id: household_id)

        youth_1 = create_client_with_warehouse_link(uid: 'client_youth_y1', dob: dob_youth_18)
        create_enrollment(client: youth_1, project: es_project, entry_date: pit_date, relationship_to_ho_h: 3, household_id: household_id) # Assuming relationship 3 for simplicity

        youth_2 = create_client_with_warehouse_link(uid: 'client_youth_y2', dob: dob_youth_20)
        create_enrollment(client: youth_2, project: es_project, entry_date: pit_date, relationship_to_ho_h: 3, household_id: household_id)

        youth_3 = create_client_with_warehouse_link(uid: 'client_youth_y3', dob: dob_youth_24)
        create_enrollment(client: youth_3, project: es_project, entry_date: pit_date, relationship_to_ho_h: 3, household_id: household_id)

        # Add a child and an older adult to ensure they are not counted
        child_member = create_client_with_warehouse_link(uid: 'client_youth_child', dob: dob_child_17)
        create_enrollment(client: child_member, project: es_project, entry_date: pit_date, relationship_to_ho_h: 3, household_id: household_id)

        adult_member = create_client_with_warehouse_link(uid: 'client_youth_adult', dob: dob_adult_25)
        create_enrollment(client: adult_member, project: es_project, entry_date: pit_date, relationship_to_ho_h: 2, household_id: household_id)
      end

      it 'counts only persons aged 18-24' do
        report = run_report(questions: [question])
        # Number of Persons (18 - 24) is B5 for AdultAndChild question
        youth_count = report.answer(question: question, cell: 'B5')
        expect(youth_count.value).to eq(3)
      end
    end

    context 'when there are no youth (18-24)' do
      before do
        household_id = 'hh_no_youth_1'
        hoh_client = create_client_with_warehouse_link(uid: 'client_noyouth_hoh', dob: dob_adult_25)
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: 1, household_id: household_id)

        child_member = create_client_with_warehouse_link(uid: 'client_noyouth_child', dob: dob_child_17)
        create_enrollment(client: child_member, project: es_project, entry_date: pit_date, relationship_to_ho_h: 3, household_id: household_id)
      end

      it 'counts zero youth' do
        report = run_report(questions: [question])
        youth_count = report.answer(question: question, cell: 'B5')
        expect(youth_count.value).to eq(0)
      end
    end

    context 'for Persons Ages 25-34' do
      let(:question) { HudPit::Generators::Pit::Fy2025::Adults::QUESTION_NUMBER }
      let(:dob_age_25) { pit_date - 25.years } # Exactly 25
      let(:dob_age_30) { pit_date - 30.years } # Exactly 30
      let(:dob_age_34) { pit_date - 34.years } # Exactly 34
      let(:dob_age_24) { pit_date - 24.years } # Exactly 24 (too young)
      let(:dob_age_35) { pit_date - 35.years } # Exactly 35 (too old)

      before do
        household_id = 'hh_age_25_34_1'
        # HoH (outside this age range for simplicity of member counting)
        hoh_client = create_client_with_warehouse_link(uid: 'client_a2534_hoh', dob: pit_date - 40.years)
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: 1, household_id: household_id)

        # Members in 25-34 age group
        m1 = create_client_with_warehouse_link(uid: 'client_a2534_m1', dob: dob_age_25)
        create_enrollment(client: m1, project: es_project, entry_date: pit_date, relationship_to_ho_h: 2, household_id: household_id)
        m2 = create_client_with_warehouse_link(uid: 'client_a2534_m2', dob: dob_age_30)
        create_enrollment(client: m2, project: es_project, entry_date: pit_date, relationship_to_ho_h: 2, household_id: household_id)
        m3 = create_client_with_warehouse_link(uid: 'client_a2534_m3', dob: dob_age_34)
        create_enrollment(client: m3, project: es_project, entry_date: pit_date, relationship_to_ho_h: 2, household_id: household_id)

        # Members outside this age group
        m_young = create_client_with_warehouse_link(uid: 'client_a2534_m_young', dob: dob_age_24)
        create_enrollment(client: m_young, project: es_project, entry_date: pit_date, relationship_to_ho_h: 3, household_id: household_id)
        m_old = create_client_with_warehouse_link(uid: 'client_a2534_m_old', dob: dob_age_35)
        create_enrollment(client: m_old, project: es_project, entry_date: pit_date, relationship_to_ho_h: 2, household_id: household_id)
      end

      it 'counts only persons aged 25-34' do
        report = run_report(questions: [question])
        # Number of Persons (25 - 34) is B6 for AdultAndChild question
        age_25_34_count = report.answer(question: question, cell: 'B5')
        expect(age_25_34_count.value).to eq(3)
      end
    end

    context 'for Persons Ages 35-44' do
      let(:question) { HudPit::Generators::Pit::Fy2025::Adults::QUESTION_NUMBER }
      let(:dob_age_35) { pit_date - 35.years } # Exactly 35
      let(:dob_age_40) { pit_date - 40.years } # Exactly 40
      let(:dob_age_44) { pit_date - 44.years } # Exactly 44
      let(:dob_age_34) { pit_date - 34.years } # Exactly 34 (too young)
      let(:dob_age_45) { pit_date - 45.years } # Exactly 45 (too old)

      before do
        household_id = 'hh_age_35_44_1'
        hoh_client = create_client_with_warehouse_link(uid: 'client_a3544_hoh', dob: pit_date - 50.years)
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: 1, household_id: household_id)

        m1 = create_client_with_warehouse_link(uid: 'client_a3544_m1', dob: dob_age_35)
        create_enrollment(client: m1, project: es_project, entry_date: pit_date, relationship_to_ho_h: 2, household_id: household_id)
        m2 = create_client_with_warehouse_link(uid: 'client_a3544_m2', dob: dob_age_40)
        create_enrollment(client: m2, project: es_project, entry_date: pit_date, relationship_to_ho_h: 2, household_id: household_id)
        m3 = create_client_with_warehouse_link(uid: 'client_a3544_m3', dob: dob_age_44)
        create_enrollment(client: m3, project: es_project, entry_date: pit_date, relationship_to_ho_h: 2, household_id: household_id)

        m_young = create_client_with_warehouse_link(uid: 'client_a3544_m_young', dob: dob_age_34)
        create_enrollment(client: m_young, project: es_project, entry_date: pit_date, relationship_to_ho_h: 2, household_id: household_id)
        m_old = create_client_with_warehouse_link(uid: 'client_a3544_m_old', dob: dob_age_45)
        create_enrollment(client: m_old, project: es_project, entry_date: pit_date, relationship_to_ho_h: 2, household_id: household_id)
      end

      it 'counts only persons aged 35-44' do
        report = run_report(questions: [question])
        # Number of Persons (35 - 44) is B7 for AdultAndChild question
        age_35_44_count = report.answer(question: question, cell: 'B6')
        expect(age_35_44_count.value).to eq(3)
      end
    end

    context 'for Persons Ages 45-54' do
      let(:question) { HudPit::Generators::Pit::Fy2025::Adults::QUESTION_NUMBER }
      let(:dob_age_45) { pit_date - 45.years } # Exactly 45
      let(:dob_age_50) { pit_date - 50.years } # Exactly 50
      let(:dob_age_54) { pit_date - 54.years } # Exactly 54
      let(:dob_age_44) { pit_date - 44.years } # Exactly 44 (too young)
      let(:dob_age_55) { pit_date - 55.years } # Exactly 55 (too old)

      before do
        household_id = 'hh_age_45_54_1'
        hoh_client = create_client_with_warehouse_link(uid: 'client_a4554_hoh', dob: pit_date - 60.years)
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: 1, household_id: household_id)

        m1 = create_client_with_warehouse_link(uid: 'client_a4554_m1', dob: dob_age_45)
        create_enrollment(client: m1, project: es_project, entry_date: pit_date, relationship_to_ho_h: 2, household_id: household_id)
        m2 = create_client_with_warehouse_link(uid: 'client_a4554_m2', dob: dob_age_50)
        create_enrollment(client: m2, project: es_project, entry_date: pit_date, relationship_to_ho_h: 2, household_id: household_id)
        m3 = create_client_with_warehouse_link(uid: 'client_a4554_m3', dob: dob_age_54)
        create_enrollment(client: m3, project: es_project, entry_date: pit_date, relationship_to_ho_h: 2, household_id: household_id)

        m_young = create_client_with_warehouse_link(uid: 'client_a4554_m_young', dob: dob_age_44)
        create_enrollment(client: m_young, project: es_project, entry_date: pit_date, relationship_to_ho_h: 2, household_id: household_id)
        m_old = create_client_with_warehouse_link(uid: 'client_a4554_m_old', dob: dob_age_55)
        create_enrollment(client: m_old, project: es_project, entry_date: pit_date, relationship_to_ho_h: 2, household_id: household_id)
      end

      it 'counts only persons aged 45-54' do
        report = run_report(questions: [question])
        # Number of Persons (45 - 54) is B8 for AdultAndChild question
        age_45_54_count = report.answer(question: question, cell: 'B7')
        expect(age_45_54_count.value).to eq(3)
      end
    end

    context 'for Persons Ages 55-64' do
      let(:question) { HudPit::Generators::Pit::Fy2025::Adults::QUESTION_NUMBER }
      let(:dob_age_55) { pit_date - 55.years } # Exactly 55
      let(:dob_age_60) { pit_date - 60.years } # Exactly 60
      let(:dob_age_64) { pit_date - 64.years } # Exactly 64
      let(:dob_age_54) { pit_date - 54.years } # Exactly 54 (too young)
      let(:dob_age_65) { pit_date - 65.years } # Exactly 65 (too old)

      before do
        household_id = 'hh_age_55_64_1'
        hoh_client = create_client_with_warehouse_link(uid: 'client_a5564_hoh', dob: pit_date - 70.years)
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: 1, household_id: household_id)

        m1 = create_client_with_warehouse_link(uid: 'client_a5564_m1', dob: dob_age_55)
        create_enrollment(client: m1, project: es_project, entry_date: pit_date, relationship_to_ho_h: 2, household_id: household_id)
        m2 = create_client_with_warehouse_link(uid: 'client_a5564_m2', dob: dob_age_60)
        create_enrollment(client: m2, project: es_project, entry_date: pit_date, relationship_to_ho_h: 2, household_id: household_id)
        m3 = create_client_with_warehouse_link(uid: 'client_a5564_m3', dob: dob_age_64)
        create_enrollment(client: m3, project: es_project, entry_date: pit_date, relationship_to_ho_h: 2, household_id: household_id)

        m_young = create_client_with_warehouse_link(uid: 'client_a5564_m_young', dob: dob_age_54)
        create_enrollment(client: m_young, project: es_project, entry_date: pit_date, relationship_to_ho_h: 2, household_id: household_id)
        m_old = create_client_with_warehouse_link(uid: 'client_a5564_m_old', dob: dob_age_65)
        create_enrollment(client: m_old, project: es_project, entry_date: pit_date, relationship_to_ho_h: 2, household_id: household_id)
      end

      it 'counts only persons aged 55-64' do
        report = run_report(questions: [question])
        # Number of Persons (55 - 64) is B9 for AdultAndChild question
        age_55_64_count = report.answer(question: question, cell: 'B8')
        expect(age_55_64_count.value).to eq(3)
      end
    end

    context 'for Persons Ages 65+' do
      let(:question) { HudPit::Generators::Pit::Fy2025::Adults::QUESTION_NUMBER }
      let(:dob_age_65) { pit_date - 65.years } # Exactly 65
      let(:dob_age_70) { pit_date - 70.years } # Exactly 70
      let(:dob_age_64) { pit_date - 64.years } # Exactly 64 (too young)

      before do
        household_id = 'hh_age_65_plus_1'
        hoh_client = create_client_with_warehouse_link(uid: 'client_a65p_hoh', dob: pit_date - 40.years) # Younger HoH for simplicity
        create_enrollment(client: hoh_client, project: es_project, entry_date: pit_date, relationship_to_ho_h: 1, household_id: household_id)

        m1 = create_client_with_warehouse_link(uid: 'client_a65p_m1', dob: dob_age_65)
        create_enrollment(client: m1, project: es_project, entry_date: pit_date, relationship_to_ho_h: 2, household_id: household_id)
        m2 = create_client_with_warehouse_link(uid: 'client_a65p_m2', dob: dob_age_70)
        create_enrollment(client: m2, project: es_project, entry_date: pit_date, relationship_to_ho_h: 2, household_id: household_id)

        m_young = create_client_with_warehouse_link(uid: 'client_a65p_m_young', dob: dob_age_64)
        create_enrollment(client: m_young, project: es_project, entry_date: pit_date, relationship_to_ho_h: 2, household_id: household_id)
      end

      it 'counts only persons aged 65 and older' do
        report = run_report(questions: [question])
        # Number of Persons (65 and older) is B10 for AdultAndChild question
        age_65_plus_count = report.answer(question: question, cell: 'B9')
        expect(age_65_plus_count.value).to eq(2)
      end
    end
  end
  # Tests for basic household and person counts, including age breakdowns
end
