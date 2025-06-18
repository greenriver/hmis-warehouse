# frozen_string_literal: true

require_relative '../../../support/ce_spec_helper'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'ce spec helper'

  before(:each) do
    hmis_login(user)
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
        2.times do
          step = referral.workflow_engine.active_steps.first
          referral.workflow_engine.start_step!(step, user: hmis_user)
          referral.workflow_engine.complete_step!(step, user: hmis_user, submitted_values: { client_accepted: 1 })
        end
      end

      it 'returns step completion and accept referral events' do
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect
        events = result.dig('data', 'ceReferral', 'events', 'nodes')
        expect(events.length).to eq(4)
        expect(events).to match_array(
          [
            a_hash_including(
              'type' => 'Accepted Referral',
            ),
            a_hash_including(
              'type' => 'Completed Task',
              'stepName' => 'Provider Acceptance',
            ),
            a_hash_including(
              'type' => 'Completed Task',
              'stepName' => 'Client Acceptance',
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
        2.times do
          step = referral.workflow_engine.active_steps.first
          referral.workflow_engine.start_step!(step, user: hmis_user)
          referral.workflow_engine.complete_step!(step, user: hmis_user, submitted_values: { client_accepted: 0 })
        end
      end

      it 'returns step completion and reject referral events' do
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect
        events = result.dig('data', 'ceReferral', 'events', 'nodes')
        expect(events.length).to eq(4)
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
              'stepName' => 'Provider Acceptance',
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
