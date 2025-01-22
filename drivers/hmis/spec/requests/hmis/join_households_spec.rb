###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

#  Copyright 2016 - 2025 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'
  let!(:access_control) { create_access_control(hmis_user, ds1) }
  before(:each) do
    hmis_login(user)
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation JoinHouseholds($input: JoinHouseholdsInput!) {
        joinHouseholds(input: $input) {
          receivingHousehold {
            id
            householdSize
            householdClients {
              client {
                id
              }
              enrollment {
                id
              }
            }
          }
          donorHousehold {
            id
            householdSize
          }
        }
      }
    GRAPHQL
  end

  let!(:receiving_enrollment) { create :hmis_hud_enrollment, data_source: ds1, project: p1, entry_date: 2.weeks.ago }

  let!(:donor_household_id) { Hmis::Hud::Base.generate_uuid }
  let!(:joining_e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, entry_date: 2.weeks.ago, household_id: donor_household_id }
  let!(:joining_e2) { create :hmis_hud_enrollment, data_source: ds1, project: p1, entry_date: 2.weeks.ago, relationship_to_hoh: 2, household_id: donor_household_id }

  def perform_mutation(
    receiving_household_id = receiving_enrollment.household_id,
    joining_enrollment_inputs = [
      {
        enrollment_id: joining_e1.id,
        relationship_to_hoh: 'SPOUSE_OR_PARTNER',
      },
      {
        enrollment_id: joining_e2.id,
        relationship_to_hoh: 'CHILD',
      },
    ]
  )
    input = {
      input: {
        receiving_household_id: receiving_household_id,
        joining_enrollment_inputs: joining_enrollment_inputs,
      },
    }
    response, result = post_graphql(input) { mutation }

    expect(response.status).to eq(200), result.inspect
    result = result.dig('data', 'joinHouseholds')
    return result['receivingHousehold'], result['donorHousehold']
  end

  it 'should successfully join households' do
    expect do
      joined_household, donor_household = perform_mutation
      expect(joined_household.dig('id')).to eq(receiving_enrollment.household_id)
      expect(joined_household.dig('householdSize')).to eq(3)
      expect(donor_household).to be_nil # No remaining members in donor household
      receiving_enrollment.reload
      joining_e1.reload
      joining_e2.reload
    end.to change(joining_e1, :household_id).to(receiving_enrollment.household_id).
      and change(joining_e2, :household_id).to(receiving_enrollment.household_id)

    join_event = joining_e1.household.events.sole
    expect(join_event.household).to eq(receiving_enrollment.household)
    expect(join_event.event_type).to eq('join')
    dets = join_event.event_details
    expect(dets['donorHouseholdId']).to eq(donor_household_id)
    expect(dets['before'].map { |enrollment_snap| enrollment_snap['enrollmentId'] }).to contain_exactly(receiving_enrollment.id)
    expect(dets['after'].map { |enrollment_snap| enrollment_snap['enrollmentId'] }).to contain_exactly(receiving_enrollment.id, joining_e1.id, joining_e2.id)

    leave_event = Hmis::HouseholdEvent.where(event_type: 'split').last # Household no longer exists, so query for it directly
    expect(leave_event.household_id).to eq(donor_household_id)
    dets = leave_event.event_details
    expect(dets['receivingHouseholdId']).to eq(receiving_enrollment.household.household_id)
    expect(dets['before'].map { |enrollment_snap| enrollment_snap['enrollmentId'] }).to contain_exactly(joining_e1.id, joining_e2.id)
    expect(dets['after'].map { |enrollment_snap| enrollment_snap['enrollmentId'] }).to be_empty
  end

  context 'when there are remaining members left behind in the donor household' do
    let!(:joining_e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, entry_date: 2.weeks.ago, relationship_to_hoh: 3, household_id: donor_household_id }
    let!(:remaining_member) { create :hmis_hud_enrollment, data_source: ds1, project: p1, entry_date: 2.weeks.ago, household_id: donor_household_id }

    it 'returns the remaining donor household' do
      expect do
        joined_household, donor_household = perform_mutation
        expect(joined_household.dig('id')).to eq(receiving_enrollment.household_id)
        expect(donor_household.dig('id')).to eq(donor_household_id)
        expect(donor_household.dig('householdSize')).to eq(1)
        joining_e1.reload
        joining_e2.reload
        remaining_member.reload
      end.to change(joining_e1, :household_id).to(receiving_enrollment.household_id).
        and change(joining_e2, :household_id).to(receiving_enrollment.household_id).
        and not_change(remaining_member, :household_id)

      join_event = joining_e1.household.events.sole
      expect(join_event.household).to eq(receiving_enrollment.household)
      expect(join_event.event_type).to eq('join')
      dets = join_event.event_details
      expect(dets['donorHouseholdId']).to eq(donor_household_id)
      expect(dets['before'].map { |enrollment_snap| enrollment_snap['enrollmentId'] }).to contain_exactly(receiving_enrollment.id)
      expect(dets['after'].map { |enrollment_snap| enrollment_snap['enrollmentId'] }).to contain_exactly(receiving_enrollment.id, joining_e1.id, joining_e2.id)

      leave_event = remaining_member.household.events.sole
      expect(leave_event.household_id).to eq(donor_household_id)
      dets = leave_event.event_details
      expect(dets['receivingHouseholdId']).to eq(receiving_enrollment.household.household_id)
      expect(dets['before'].map { |enrollment_snap| enrollment_snap['enrollmentId'] }).to contain_exactly(remaining_member.id, joining_e1.id, joining_e2.id)
      expect(dets['after'].map { |enrollment_snap| enrollment_snap['enrollmentId'] }).to contain_exactly(remaining_member.id)
    end
  end

  context 'when the receiving household has no HoH (bad data)' do
    let!(:receiving_enrollment) { create :hmis_hud_enrollment, relationship_to_hoh: 99, data_source: ds1, project: p1, entry_date: 2.weeks.ago }

    it 'still successfully joins' do
      expect do
        joining_enrollment_inputs = [
          {
            enrollment_id: joining_e2.id,
            relationship_to_hoh: 'SPOUSE_OR_PARTNER',
          },
        ]
        joined_household, donor_household = perform_mutation(receiving_enrollment.household_id, joining_enrollment_inputs)
        expect(joined_household.dig('id')).to eq(receiving_enrollment.household_id)
        expect(donor_household.dig('householdSize')).to eq(1)
        joining_e2.reload
      end.to change(joining_e2, :household_id).to(receiving_enrollment.household_id)
    end
  end

  describe 'unit assignment' do
    let!(:unit1) { create :hmis_unit, project: p1 }

    context 'when the receiving household has a unit' do
      let!(:receiving_occupancy) { create :hmis_unit_occupancy, unit: unit1, enrollment: receiving_enrollment }

      it 'adds the joining household members to the unit' do
        expect do
          perform_mutation
          joining_e1.reload
          joining_e2.reload
        end.to change(joining_e1, :active_unit_occupancy).
          and change(joining_e2, :active_unit_occupancy).
          and not_change(receiving_enrollment, :active_unit_occupancy)

        expect(joining_e1.active_unit_occupancy.unit).to eq(receiving_enrollment.active_unit_occupancy.unit)
        expect(joining_e2.active_unit_occupancy.unit).to eq(receiving_enrollment.active_unit_occupancy.unit)
      end

      context 'when the receiving household has several units' do
        let!(:unit2) { create :hmis_unit, project: p1 }
        let!(:receiving_member) { create :hmis_hud_enrollment, data_source: ds1, project: p1, entry_date: 2.weeks.ago, relationship_to_hoh: 3, household_id: receiving_enrollment.household_id }
        let!(:receiving_occupancy_2) { create :hmis_unit_occupancy, unit: unit2, enrollment: receiving_member }

        it 'distributes the joining enrollments across units' do
          expect do
            perform_mutation
            joining_e1.reload
            joining_e2.reload
          end.to change(joining_e1, :active_unit_occupancy).
            and change(joining_e2, :active_unit_occupancy)

          expect(joining_e1.active_unit_occupancy.unit).to eq(unit1)
          expect(joining_e2.active_unit_occupancy.unit).to eq(unit2)
        end
      end
    end

    context 'when the joining enrollment has a unit but the receiving household does not' do
      let!(:joining_e1_occupancy) { create :hmis_unit_occupancy, unit: unit1, enrollment: joining_e1 }
      let!(:joining_e2_occupancy) { create :hmis_unit_occupancy, unit: unit1, enrollment: joining_e2 }

      it 'removes the current unit occupancy from the joiners' do
        expect do
          perform_mutation
          joining_e1.reload
          joining_e2.reload
        end.to change(joining_e1, :active_unit_occupancy).to(nil).
          and change(joining_e2, :active_unit_occupancy).to(nil)
      end
    end
  end

  it 'fails when the given household ID is invalid' do
    input = {
      receiving_household_id: 'fake-household',
      joining_enrollment_inputs: [],
    }
    expect_access_denied post_graphql(input: input) { mutation }
  end

  it 'fails when the user does not have can_split_households permission' do
    remove_permissions(access_control, :can_split_households)
    input = {
      receiving_household_id: receiving_enrollment.household_id,
      joining_enrollment_inputs: [],
    }
    expect_access_denied post_graphql(input: input) { mutation }
  end

  it 'fails when the given joining enrollment IDs are invalid' do
    input = {
      receiving_household_id: receiving_enrollment.household_id,
      joining_enrollment_inputs: [
        {
          enrollment_id: 'fake-enrollment',
          relationship_to_hoh: 'SPOUSE_OR_PARTNER',
        },
      ],
    }
    expect_access_denied post_graphql(input: input) { mutation }
  end

  it 'fails when the given joining enrollment ID comes from a different project' do
    p2 = create :hmis_hud_project, data_source: ds1, organization: o1, user: u1
    e2 = create :hmis_hud_enrollment, data_source: ds1, project: p2
    input = {
      receiving_household_id: receiving_enrollment.household_id,
      joining_enrollment_inputs: [
        {
          enrollment_id: e2.id,
          relationship_to_hoh: 'SPOUSE_OR_PARTNER',
        },
      ],
    }
    expect_gql_error post_graphql(input: input) { mutation }, message: /Cannot merge enrollments from another project/
  end

  it 'fails when the join would leave behind a headless household' do
    input = {
      receiving_household_id: receiving_enrollment.household_id,
      joining_enrollment_inputs: [
        {
          enrollment_id: joining_e1.id,
          relationship_to_hoh: 'SPOUSE_OR_PARTNER',
        },
      ],
    }
    expect_gql_error post_graphql(input: input) { mutation }, message: /This operation would leave behind a household with no HoH/
  end
end
