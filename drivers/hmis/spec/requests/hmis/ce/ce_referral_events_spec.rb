# frozen_string_literal: true

require_relative '../../../support/ce_spec_helper'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'ce spec helper'

  before(:each) do
    hmis_login(user)
  end

  # todo @martha - this is some repeated code that maybe points to need for some restructuring
  # it seems like THIS is the thing that should be provided by ce_referral_helper, but who knows how many tests that will break.
  let(:acceptance_gateway) do
    create(
      :hmis_workflow_definition_gateway,
      template: workflow_template,
      gateway_type: 'exclusive',
      name: 'acceptance gw',
    )
  end

  let(:reject_referral) do
    create(
      :hmis_workflow_definition_end_event,
      template: workflow_template,
      name: 'reject referral',
      trigger_config: [
        {
          event: 'end_workflow',
          message: 'reject_referral',
        },
      ],
    )
  end

  before do
    client_acceptance_task.outflows.destroy_all
    client_acceptance_task.connect_to!(acceptance_gateway)
    acceptance_gateway.connect_to!(reject_referral, condition: 'client_accepted = 0')
    acceptance_gateway.connect_to!(accept_referral, condition: 'client_accepted = 1')
  end

  before do
    referral.workflow_engine.start_workflow!(user: hmis_user)
  end

  describe 'ce_referral events query' do
    let(:query) do
      <<~GRAPHQL
        query GetCeReferral($id: ID!) {
          ceReferral(id: $id) {
            id
            events {
              nodes {
                id
                stepName
                type
                user {
                  id
                  name
                }
              }
            }
          }
        }
      GRAPHQL
    end

    let(:variables) do
      {
        id: referral.id,
      }
    end

    context 'when referral is started' do
      it 'returns referral start event' do
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect
        events = result.dig('data', 'ceReferral', 'events', 'nodes')
        expect(events.length).to eq(1)
        expect(events.sole['type']).to eq('Started Referral')
      end
    end

    context 'when referral is accepted' do
      before do
        step = referral.workflow_engine.active_steps.first
        referral.workflow_engine.start_step!(step, user: hmis_user)
        referral.workflow_engine.complete_step!(step, user: hmis_user, submitted_values: { client_accepted: 1 })
      end

      it 'returns step completion and accept referral events' do
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect
        events = result.dig('data', 'ceReferral', 'events', 'nodes')
        expect(events.length).to eq(3)
        expect(events).to match_array(
          [
            a_hash_including(
              'type' => 'Accepted Referral',
            ),
            a_hash_including(
              'type' => 'Completed Task',
            ),
            a_hash_including(
              'type' => 'Started Referral',
            ),
          ],
        )
      end
    end

    context 'when referral is rejected' do
      before do
        step = referral.workflow_engine.active_steps.first
        referral.workflow_engine.start_step!(step, user: hmis_user)
        referral.workflow_engine.complete_step!(step, user: hmis_user, submitted_values: { client_accepted: 0 })
      end

      it 'returns step completion and reject referral events' do
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect
        events = result.dig('data', 'ceReferral', 'events', 'nodes')
        expect(events.length).to eq(3)
        expected_user = a_hash_including(
          'id' => hmis_user.id.to_s,
          'name' => hmis_user.name.to_s,
        )
        expect(events).to match_array(
          [
            a_hash_including(
              'user' => expected_user,
              'type' => 'Declined Referral',
            ),
            a_hash_including(
              'user' => expected_user,
              'type' => 'Completed Task',
              'stepName' => 'Client Acceptance',
            ),
            a_hash_including(
              'user' => expected_user,
              'type' => 'Started Referral',
            ),
          ],
        )
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
