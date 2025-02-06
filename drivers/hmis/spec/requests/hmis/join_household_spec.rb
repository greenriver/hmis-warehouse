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
      mutation JoinHousehold($receivingHouseholdId: ID!, $joiningEnrollmentInputs: [EnrollmentRelationshipInput!]!) {
        joinHousehold(receivingHouseholdId:$receivingHouseholdId, joiningEnrollmentInputs:$joiningEnrollmentInputs) {
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
          }
        }
      }
    GRAPHQL
  end

  let!(:receiving_enrollment) { create :hmis_hud_enrollment, data_source: ds1, project: p1, entry_date: 2.weeks.ago }

  let!(:donor_household_id) { Hmis::Hud::Base.generate_uuid }
  let!(:donor_hoh) { create :hmis_hud_enrollment, data_source: ds1, project: p1, entry_date: 2.weeks.ago, household_id: donor_household_id }
  let!(:donor_child) { create :hmis_hud_enrollment, data_source: ds1, project: p1, entry_date: 2.weeks.ago, relationship_to_hoh: 2, household_id: donor_household_id }

  def perform_mutation(
    receiving_household_id = receiving_enrollment.household_id,
    joining_enrollment_inputs = [
      {
        enrollment_id: donor_hoh.id,
        relationship_to_hoh: 'SPOUSE_OR_PARTNER',
      },
      {
        enrollment_id: donor_child.id,
        relationship_to_hoh: 'CHILD',
      },
    ]
  )
    input = {
      receiving_household_id: receiving_household_id,
      joining_enrollment_inputs: joining_enrollment_inputs,
    }
    response, result = post_graphql(input) { mutation }

    expect(response.status).to eq(200), result.inspect
    result = result.dig('data', 'joinHousehold')
    return result['receivingHousehold'], result['donorHousehold']
  end

  it 'should successfully join households' do
    expect do
      joined_household, donor_household = perform_mutation
      expect(joined_household.dig('id')).to eq(receiving_enrollment.household_id)
      expect(joined_household.dig('householdSize')).to eq(3)
      expect(donor_household).to be_nil # No remaining members in donor household
      receiving_enrollment.reload
      donor_hoh.reload
      donor_child.reload
    end.to change(donor_hoh, :household_id).to(receiving_enrollment.household_id).
      and change(donor_child, :household_id).to(receiving_enrollment.household_id)

    join_event = donor_hoh.household.events.sole
    expect(join_event.household).to eq(receiving_enrollment.household)
    expect(join_event.event_type).to eq('join')
    dets = join_event.event_details
    expect(dets['donor_household_id']).to eq(donor_household_id)
    expect(dets['before'].map { |enrollment_snap| enrollment_snap['enrollment_id'] }).to contain_exactly(receiving_enrollment.id)
    expect(dets['after'].map { |enrollment_snap| enrollment_snap['enrollment_id'] }).to contain_exactly(receiving_enrollment.id, donor_hoh.id, donor_child.id)

    leave_event = Hmis::HouseholdEvent.where(event_type: 'split').last # Household no longer exists, so query for it directly
    expect(leave_event.household_id).to eq(donor_household_id)
    dets = leave_event.event_details
    expect(dets['receiving_household_id']).to eq(receiving_enrollment.household.household_id)
    expect(dets['before'].map { |enrollment_snap| enrollment_snap['enrollment_id'] }).to contain_exactly(donor_hoh.id, donor_child.id)
    expect(dets['after'].map { |enrollment_snap| enrollment_snap['enrollment_id'] }).to be_empty
  end

  context 'when there are remaining members left behind in the donor household' do
    let!(:donor_hoh) { create :hmis_hud_enrollment, data_source: ds1, project: p1, entry_date: 2.weeks.ago, relationship_to_hoh: 3, household_id: donor_household_id }
    let!(:remaining_member) { create :hmis_hud_enrollment, data_source: ds1, project: p1, entry_date: 2.weeks.ago, household_id: donor_household_id }

    it 'returns the remaining donor household' do
      expect do
        joined_household, donor_household = perform_mutation
        expect(joined_household.dig('id')).to eq(receiving_enrollment.household_id)
        expect(donor_household.dig('id')).to eq(remaining_member.household_id.to_s)
        donor_hoh.reload
        donor_child.reload
        remaining_member.reload
      end.to change(donor_hoh, :household_id).to(receiving_enrollment.household_id).
        and change(donor_child, :household_id).to(receiving_enrollment.household_id).
        and not_change(remaining_member, :household_id)

      join_event = donor_hoh.household.events.sole
      expect(join_event.household).to eq(receiving_enrollment.household)
      expect(join_event.event_type).to eq('join')
      dets = join_event.event_details
      expect(dets['donor_household_id']).to eq(donor_household_id)
      expect(dets['before'].map { |enrollment_snap| enrollment_snap['enrollment_id'] }).to contain_exactly(receiving_enrollment.id)
      expect(dets['after'].map { |enrollment_snap| enrollment_snap['enrollment_id'] }).to contain_exactly(receiving_enrollment.id, donor_hoh.id, donor_child.id)

      leave_event = remaining_member.household.events.sole
      expect(leave_event.household_id).to eq(donor_household_id)
      dets = leave_event.event_details
      expect(dets['receiving_household_id']).to eq(receiving_enrollment.household.household_id)
      expect(dets['before'].map { |enrollment_snap| enrollment_snap['enrollment_id'] }).to contain_exactly(remaining_member.id, donor_hoh.id, donor_child.id)
      expect(dets['after'].map { |enrollment_snap| enrollment_snap['enrollment_id'] }).to contain_exactly(remaining_member.id)
    end
  end

  context 'when the receiving household has no HoH (bad data)' do
    let!(:receiving_enrollment) { create :hmis_hud_enrollment, relationship_to_hoh: 99, data_source: ds1, project: p1, entry_date: 2.weeks.ago }

    it 'still successfully joins' do
      expect do
        joining_enrollment_inputs = [
          {
            enrollment_id: donor_child.id,
            relationship_to_hoh: 'SPOUSE_OR_PARTNER',
          },
        ]
        joined_household, donor_household = perform_mutation(receiving_enrollment.household_id, joining_enrollment_inputs)
        expect(joined_household.dig('id')).to eq(receiving_enrollment.household_id)
        expect(donor_household.dig('id')).to eq(donor_hoh.household_id.to_s)
        donor_child.reload
      end.to change(donor_child, :household_id).to(receiving_enrollment.household_id)
    end
  end

  describe 'unit assignment' do
    let!(:unit1) { create :hmis_unit, project: p1 }

    context 'when the receiving household has a unit' do
      let!(:receiving_occupancy) { create :hmis_unit_occupancy, unit: unit1, enrollment: receiving_enrollment }

      it 'adds the joining household members to the unit' do
        expect do
          perform_mutation
          donor_hoh.reload
          donor_child.reload
        end.to change(donor_hoh, :active_unit_occupancy).
          and change(donor_child, :active_unit_occupancy).
          and not_change(receiving_enrollment, :active_unit_occupancy)

        expect(donor_hoh.active_unit_occupancy.unit).to eq(receiving_enrollment.active_unit_occupancy.unit)
        expect(donor_child.active_unit_occupancy.unit).to eq(receiving_enrollment.active_unit_occupancy.unit)
      end
    end

    context 'when the joining enrollment has a unit but the receiving household does not' do
      let!(:donor_hoh_occupancy) { create :hmis_unit_occupancy, unit: unit1, enrollment: donor_hoh }
      let!(:donor_child_occupancy) { create :hmis_unit_occupancy, unit: unit1, enrollment: donor_child }

      it 'removes the current unit occupancy from the joiners' do
        expect do
          perform_mutation
          donor_hoh.reload
          donor_child.reload
        end.to change(donor_hoh, :active_unit_occupancy).to(nil).
          and change(donor_child, :active_unit_occupancy).to(nil)
      end
    end
  end

  it 'fails when the given household ID is invalid' do
    input = {
      receiving_household_id: 'fake-household',
      joining_enrollment_inputs: [],
    }
    expect_access_denied post_graphql(**input) { mutation }
  end

  it 'fails when the user does not have can_split_households permission' do
    remove_permissions(access_control, :can_split_households)
    input = {
      receiving_household_id: receiving_enrollment.household_id,
      joining_enrollment_inputs: [],
    }
    expect_access_denied post_graphql(**input) { mutation }
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
    expect_access_denied post_graphql(**input) { mutation }
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
    expect_access_denied post_graphql(**input) { mutation }
  end

  it 'fails when the join would leave behind a headless household' do
    input = {
      receiving_household_id: receiving_enrollment.household_id,
      joining_enrollment_inputs: [
        {
          enrollment_id: donor_hoh.id,
          relationship_to_hoh: 'SPOUSE_OR_PARTNER',
        },
      ],
    }
    expect_gql_error post_graphql(**input) { mutation }, message: /This operation would leave behind a household with no HoH/
  end
end
