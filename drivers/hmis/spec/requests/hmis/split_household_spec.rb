###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'
  let!(:access_control) { create_access_control(hmis_user, ds1) }

  let(:mutation) do
    <<~GRAPHQL
      mutation SplitHousehold($input: SplitHouseholdInput!) {
        splitHousehold(input: $input) {
          newHousehold {
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
          remainingHousehold {
            id
            householdSize
          }
        }
      }
    GRAPHQL
  end

  let!(:donor_household_id) { Hmis::Hud::Base.generate_uuid }
  let!(:remaining) { create :hmis_hud_enrollment, data_source: ds1, project: p1, entry_date: 2.weeks.ago, household_id: donor_household_id }
  let!(:new_hoh) { create :hmis_hud_enrollment, data_source: ds1, project: p1, entry_date: 2.weeks.ago, relationship_to_hoh: 3, household_id: donor_household_id }
  let!(:child) { create :hmis_hud_enrollment, data_source: ds1, project: p1, entry_date: 2.weeks.ago, relationship_to_hoh: 2, household_id: donor_household_id }

  before(:each) do
    hmis_login(user)
    remaining.update!(processed_as: 'PROCESSED', processed_hash: 'PROCESSED')
    new_hoh.update!(processed_as: 'PROCESSED', processed_hash: 'PROCESSED')
    child.update!(processed_as: 'PROCESSED', processed_hash: 'PROCESSED')
    Delayed::Job.jobs_for_class('GrdaWarehouse::Tasks::ServiceHistory::Enrollment').delete_all
  end

  def perform_mutation(
    splitting_enrollment_inputs = [
      {
        enrollment_id: new_hoh.id,
        relationship_to_hoh: 'SELF_HEAD_OF_HOUSEHOLD',
      },
      {
        enrollment_id: child.id,
        relationship_to_hoh: 'CHILD',
      },
    ]
  )
    input = {
      input: {
        splitting_enrollment_inputs: splitting_enrollment_inputs,
      },
    }
    response, result = post_graphql(input) { mutation }

    expect(response.status).to eq(200), result.inspect
    result = result.dig('data', 'splitHousehold')
    return result['newHousehold'], result['remainingHousehold']
  end

  it 'should successfully split households' do
    expect do
      new_household, remaining_household = perform_mutation
      expect(new_household.dig('householdSize')).to eq(2)
      expect(remaining_household.dig('id')).to eq(donor_household_id)
      expect(remaining_household.dig('householdSize')).to eq(1)
      remaining.reload
      new_hoh.reload
      child.reload
    end.to change(new_hoh, :household_id).
      and change(new_hoh, :processed_as).from('PROCESSED').to(nil).
      and change(child, :household_id).
      and change(child, :processed_as).from('PROCESSED').to(nil).
      and not_change(remaining, :household_id).
      and change(remaining, :processed_as).from('PROCESSED').to(nil). # Triggers reprocessing for remaining hh even though no fields have changed
      and change(Delayed::Job.jobs_for_class('GrdaWarehouse::Tasks::ServiceHistory::Enrollment'), :count).by(1)

    expect(new_hoh.household_id).to eq(child.household_id)
    expect(new_hoh.relationship_to_hoh).to eq(1) # Self
    expect(child.relationship_to_hoh).to eq(2) # Child

    split_event = remaining.household.events.sole
    expect(split_event.event_type).to eq('split')
    dets = split_event.event_details
    expect(dets['receivingHouseholdId']).to eq(new_hoh.household_id)
    expect(dets['before'].map { |enrollment_snap| enrollment_snap['enrollmentId'] }).to contain_exactly(remaining.id, new_hoh.id, child.id)
    expect(dets['after'].map { |enrollment_snap| enrollment_snap['enrollmentId'] }).to contain_exactly(remaining.id)
  end

  it 'fails when the user does not have can_split_households permission' do
    remove_permissions(access_control, :can_split_households)
    input = {
      splitting_enrollment_inputs: [
        {
          enrollment_id: new_hoh.id,
          relationship_to_hoh: 'SELF_HEAD_OF_HOUSEHOLD',
        },
      ],
    }
    expect_access_denied post_graphql(input: input) { mutation }
  end

  it 'fails when the given enrollment IDs are invalid' do
    input = {
      splitting_enrollment_inputs: [
        {
          enrollment_id: 'fake-enrollment',
          relationship_to_hoh: 'SELF_HEAD_OF_HOUSEHOLD',
        },
      ],
    }
    expect_access_denied post_graphql(input: input) { mutation }
  end

  context 'when the given enrollment IDs come from different households' do
    let!(:child) { create :hmis_hud_enrollment, data_source: ds1, project: p1, entry_date: 2.weeks.ago, relationship_to_hoh: 2 }

    it 'fails to process' do
      input = {
        splitting_enrollment_inputs: [
          {
            enrollment_id: new_hoh.id,
            relationship_to_hoh: 'SELF_HEAD_OF_HOUSEHOLD',
          },
          {
            enrollment_id: child.id,
            relationship_to_hoh: 'CHILD',
          },
        ],
      }
      expect_gql_error post_graphql(input: input) { mutation }
    end
  end

  it 'fails when the split would not leave behind any users' do
    input = {
      splitting_enrollment_inputs: [
        {
          enrollment_id: remaining.id,
          relationship_to_hoh: 'SELF_HEAD_OF_HOUSEHOLD',
        },
        {
          enrollment_id: new_hoh.id,
          relationship_to_hoh: 'SPOUSE_OR_PARTNER',
        },
        {
          enrollment_id: child.id,
          relationship_to_hoh: 'CHILD',
        },
      ],
    }
    expect_gql_error post_graphql(input: input) { mutation }, message: /Splitting all clients to a new household is invalid/
  end

  it 'fails when the split would leave behind a headless household' do
    input = {
      splitting_enrollment_inputs: [
        {
          enrollment_id: remaining.id,
          relationship_to_hoh: 'SELF_HEAD_OF_HOUSEHOLD',
        },
      ],
    }
    expect_gql_error post_graphql(input: input) { mutation }, message: /This operation would leave behind a household with no HoH, which is not allowed/
  end
end
