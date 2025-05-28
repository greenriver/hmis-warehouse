# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'hud_pit_context'

RSpec.describe 'PIT Veteran Counts', type: :model do
  include_context 'HUD pit context'

  describe 'Total Veteran Counts' do
    let(:question) { HudPit::Generators::Pit::Fy2025::VeteranAdults::QUESTION_NUMBER }
    let(:es_project) { create_project(project_type: 0) } # ES-EE
    let(:adult_dob) { pit_date - 30.years }

    context 'when there is one veteran HoH' do
      before do
        household_id = 'hh_vet_1'
        veteran_hoh = create_client_with_warehouse_link(uid: 'client_vet_hoh_1', dob: adult_dob)
        veteran_hoh.update!(VeteranStatus: 1) # Mark as veteran

        create_enrollment(
          client: veteran_hoh,
          project: es_project,
          entry_date: pit_date,
          relationship_to_ho_h: 1,
          household_id: household_id,
        )
      end

      it 'counts one veteran' do
        report = run_report(questions: [question])
        # Total Number of Veterans is B4 for VeteranAdults question
        total_veterans = report.answer(question: question, cell: 'B4')
        expect(total_veterans.value).to eq(1)
      end
    end

    context 'when there is a household with a veteran HoH and a non-veteran member' do
      before do
        household_id = 'hh_vet_2'
        veteran_hoh = create_client_with_warehouse_link(uid: 'client_vet_hoh_2', dob: adult_dob)
        veteran_hoh.update!(VeteranStatus: 1)

        non_veteran_member = create_client_with_warehouse_link(uid: 'client_non_vet_member_2', dob: adult_dob)
        non_veteran_member.update!(VeteranStatus: 0)

        create_enrollment(
          client: veteran_hoh,
          project: es_project,
          entry_date: pit_date,
          relationship_to_ho_h: 1,
          household_id: household_id,
        )
        create_enrollment(
          client: non_veteran_member,
          project: es_project,
          entry_date: pit_date,
          relationship_to_ho_h: 2, # Other adult
          household_id: household_id,
        )
      end

      it 'counts only the veteran person' do
        # The question 'Adult Only Veteran Households' filters for households where HoH is a veteran.
        # The sub_calculation for :veterans counts individuals with VeteranStatus = 1.
        report = run_report(questions: [question])
        total_veterans = report.answer(question: question, cell: 'B4')
        expect(total_veterans.value).to eq(1) # Only the HoH is a veteran

        # Check total persons in such households for context (B3 for this question type)
        total_persons_in_vet_hh = report.answer(question: question, cell: 'B3')
        expect(total_persons_in_vet_hh.value).to eq(2) # Both HoH and other member
      end
    end

    context 'when there is a household with a non-veteran HoH and a veteran member' do
      before do
        household_id = 'hh_vet_3'
        non_veteran_hoh = create_client_with_warehouse_link(uid: 'client_non_vet_hoh_3', dob: adult_dob)
        non_veteran_hoh.update!(VeteranStatus: 0)

        veteran_member = create_client_with_warehouse_link(uid: 'client_vet_member_3', dob: adult_dob)
        veteran_member.update!(VeteranStatus: 1)

        create_enrollment(
          client: non_veteran_hoh,
          project: es_project,
          entry_date: pit_date,
          relationship_to_ho_h: 1,
          household_id: household_id,
        )
        create_enrollment(
          client: veteran_member,
          project: es_project,
          entry_date: pit_date,
          relationship_to_ho_h: 2,
          household_id: household_id,
        )
      end

      it 'does not count the household or persons for this specific question type' do
        # This household won't be included by VeteranAdults::filter_pending_associations (needs HoH to be veteran)
        report = run_report(questions: [question])
        total_veterans = report.answer(question: question, cell: 'B4')
        expect(total_veterans.value).to eq(0)

        total_persons_in_vet_hh = report.answer(question: question, cell: 'B3')
        expect(total_persons_in_vet_hh.value).to eq(0)
      end
    end

    context 'when there are multiple veteran households' do
      before do
        # Household 1: Veteran HoH only
        hh_id1 = 'hh_vet_4a'
        vet_hoh1 = create_client_with_warehouse_link(uid: 'client_vet_hoh_4a', dob: adult_dob)
        vet_hoh1.update!(VeteranStatus: 1)
        create_enrollment(client: vet_hoh1, project: es_project, entry_date: pit_date, relationship_to_ho_h: 1, household_id: hh_id1)

        # Household 2: Veteran HoH and Veteran Member
        hh_id2 = 'hh_vet_4b'
        vet_hoh2 = create_client_with_warehouse_link(uid: 'client_vet_hoh_4b', dob: adult_dob)
        vet_hoh2.update!(VeteranStatus: 1)
        vet_member2 = create_client_with_warehouse_link(uid: 'client_vet_member_4b', dob: adult_dob)
        vet_member2.update!(VeteranStatus: 1)
        create_enrollment(client: vet_hoh2, project: es_project, entry_date: pit_date, relationship_to_ho_h: 1, household_id: hh_id2)
        create_enrollment(client: vet_member2, project: es_project, entry_date: pit_date, relationship_to_ho_h: 2, household_id: hh_id2)
      end

      it 'counts all veterans from qualifying households' do
        report = run_report(questions: [question])
        total_veterans = report.answer(question: question, cell: 'B4')
        expect(total_veterans.value).to eq(3) # 1 from hh1 + 2 from hh2
      end
    end
  end
end
