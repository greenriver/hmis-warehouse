# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'hud_pit_context'

RSpec.describe HudPit::Generators::Pit::Fy2025::Base, type: :model do
  describe 'PitClient max_age after running the report' do
    include_context 'HUD pit context'

    let(:es_project) { create_project(project_type: 0) }
    let(:question) { HudPit::Generators::Pit::Fy2025::Adults::QUESTION_NUMBER }

    context 'when one ES household has a single member with no DOB' do
      let!(:source_client) do
        hoh = create_client_with_warehouse_link(uid: 'pit_single_no_dob', dob: nil)
        create_enrollment(
          client: hoh,
          project: es_project,
          entry_date: pit_date,
          relationship_to_ho_h: rel_hoh,
          household_id: 'hh_pit_max_age_no_dob',
        )
        hoh
      end

      it 'persists nil max_age on the PIT client row (not 0)' do
        report = run_report(questions: [question])
        pit_client = HudPit::Fy2025::PitClient.find_by!(
          report_instance_id: report.id,
          client_id: source_client.id,
        )
        expect(pit_client.max_age).to be_nil
        expect(pit_client.household_member_count).to eq(1)
      end
    end

    context 'when one ES household has a single member with a known DOB' do
      let(:dob_adult_30) { pit_date - 30.years }

      let!(:source_client) do
        hoh = create_client_with_warehouse_link(uid: 'pit_single_age_known', dob: dob_adult_30)
        create_enrollment(
          client: hoh,
          project: es_project,
          entry_date: pit_date,
          relationship_to_ho_h: rel_hoh,
          household_id: 'hh_pit_max_age_single_known',
        )
        hoh
      end

      it 'persists max_age as that member age on PIT night' do
        report = run_report(questions: [question])
        pit_client = HudPit::Fy2025::PitClient.find_by!(
          report_instance_id: report.id,
          client_id: source_client.id,
        )
        expected_age = GrdaWarehouse::Hud::Client.age(date: pit_date, dob: dob_adult_30)
        expect(pit_client.max_age).to eq(expected_age)
        expect(pit_client.household_member_count).to eq(1)
      end
    end

    context 'when a household has two members with known DOBs' do
      let(:dob_hoh_22) { pit_date - 22.years }
      let(:dob_child_8) { pit_date - 8.years }

      let!(:hoh_client) do
        hoh = create_client_with_warehouse_link(uid: 'pit_hh2_hoh', dob: dob_hoh_22)
        create_enrollment(
          client: hoh,
          project: es_project,
          entry_date: pit_date,
          relationship_to_ho_h: rel_hoh,
          household_id: 'hh_pit_max_age_two_members',
        )
        hoh
      end

      let!(:child_client) do
        child = create_client_with_warehouse_link(uid: 'pit_hh2_child', dob: dob_child_8)
        create_enrollment(
          client: child,
          project: es_project,
          entry_date: pit_date,
          relationship_to_ho_h: rel_child,
          household_id: 'hh_pit_max_age_two_members',
        )
        child
      end

      it 'persists the same max_age for each member (oldest age in the household)' do
        report = run_report(questions: [question])
        expected_max = [
          GrdaWarehouse::Hud::Client.age(date: pit_date, dob: dob_hoh_22),
          GrdaWarehouse::Hud::Client.age(date: pit_date, dob: dob_child_8),
        ].compact.max

        pit_hoh = HudPit::Fy2025::PitClient.find_by!(
          report_instance_id: report.id,
          client_id: hoh_client.id,
        )
        pit_child = HudPit::Fy2025::PitClient.find_by!(
          report_instance_id: report.id,
          client_id: child_client.id,
        )

        expect(pit_hoh.max_age).to eq(expected_max)
        expect(pit_child.max_age).to eq(expected_max)
        expect(pit_hoh.household_member_count).to eq(2)
        expect(pit_child.household_member_count).to eq(2)
      end
    end

    context 'when a household has multiple members and the HoH has no DOB but another member does' do
      let(:dob_spouse_22) { pit_date - 22.years }

      let!(:hoh_client) do
        hoh = create_client_with_warehouse_link(uid: 'pit_hh_mixed_hoh_no_dob', dob: nil)
        create_enrollment(
          client: hoh,
          project: es_project,
          entry_date: pit_date,
          relationship_to_ho_h: rel_hoh,
          household_id: 'hh_pit_max_age_mixed_hoh_missing',
        )
        hoh
      end

      let!(:spouse_client) do
        spouse = create_client_with_warehouse_link(uid: 'pit_hh_mixed_spouse_dob', dob: dob_spouse_22)
        create_enrollment(
          client: spouse,
          project: es_project,
          entry_date: pit_date,
          relationship_to_ho_h: rel_spouse,
          household_id: 'hh_pit_max_age_mixed_hoh_missing',
        )
        spouse
      end

      it 'persists max_age from members with a DOB only' do
        report = run_report(questions: [question])
        expected_max = GrdaWarehouse::Hud::Client.age(date: pit_date, dob: dob_spouse_22)

        pit_hoh = HudPit::Fy2025::PitClient.find_by!(report_instance_id: report.id, client_id: hoh_client.id)
        pit_spouse = HudPit::Fy2025::PitClient.find_by!(report_instance_id: report.id, client_id: spouse_client.id)

        expect(pit_hoh.max_age).to eq(expected_max)
        expect(pit_spouse.max_age).to eq(expected_max)
        expect(pit_hoh.household_member_count).to eq(2)
      end
    end

    context 'when a household has multiple members and one member has no DOB but others do' do
      let(:dob_hoh_35) { pit_date - 35.years }

      let!(:hoh_client) do
        hoh = create_client_with_warehouse_link(uid: 'pit_hh_mixed_hoh_dob', dob: dob_hoh_35)
        create_enrollment(
          client: hoh,
          project: es_project,
          entry_date: pit_date,
          relationship_to_ho_h: rel_hoh,
          household_id: 'hh_pit_max_age_mixed_other_missing',
        )
        hoh
      end

      let!(:other_client) do
        other = create_client_with_warehouse_link(uid: 'pit_hh_mixed_other_no_dob', dob: nil)
        create_enrollment(
          client: other,
          project: es_project,
          entry_date: pit_date,
          relationship_to_ho_h: rel_other_adult,
          household_id: 'hh_pit_max_age_mixed_other_missing',
        )
        other
      end

      it 'persists max_age as the max of known ages (ignores members without DOB)' do
        report = run_report(questions: [question])
        expected_max = GrdaWarehouse::Hud::Client.age(date: pit_date, dob: dob_hoh_35)

        pit_hoh = HudPit::Fy2025::PitClient.find_by!(report_instance_id: report.id, client_id: hoh_client.id)
        pit_other = HudPit::Fy2025::PitClient.find_by!(report_instance_id: report.id, client_id: other_client.id)

        expect(pit_hoh.max_age).to eq(expected_max)
        expect(pit_other.max_age).to eq(expected_max)
        expect(pit_hoh.household_member_count).to eq(2)
      end
    end
  end
end
