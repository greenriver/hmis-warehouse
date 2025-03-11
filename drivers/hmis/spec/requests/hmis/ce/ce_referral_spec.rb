# frozen_string_literal: true

require 'rails_helper'
require_relative '../login_and_permissions'
require_relative './ce_spec_helper'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'ce spec helper'

  describe 'ce_referral query' do
    let(:query) do
      <<~GRAPHQL
        query GetCeReferral($id: ID!) {
          ceReferral(id: $id) {
            id
            status
            opportunity {
              id
              name
              status
            }
            steps {
              id
              name
              status
              formDefinition {
                id
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

    context 'when workflow is initialized' do
      it 'returns expected structure with correct steps' do
        _, result = post_graphql(**variables) { query }
        expect(response.status).to eq 200
        referral_data = result.dig('data', 'ceReferral')

        expect(referral_data['id']).to eq(referral.id.to_s)
        expect(referral_data['status']).to eq('initialized')

        expect(referral_data['opportunity']).to include(
          'id' => opportunity.id.to_s,
          'name' => opportunity.name,
          'status' => opportunity.status,
        )

        steps = referral_data['steps']
        expect(steps).to be_an(Array)
        expect(steps.length).to eq(2) # Should only include task nodes

        # Verify first step (Client Acceptance)
        expect(steps[0]).to include(
          'name' => 'Client Acceptance',
          'status' => 'unavailable',
          'formDefinition' => { 'id' => client_acceptance_task.form_definition.id.to_s },
        )

        # Verify second step (Provider Acceptance)
        expect(steps[1]).to include(
          'name' => 'Provider Acceptance',
          'status' => 'unavailable',
          'formDefinition' => { 'id' => provider_acceptance_task.form_definition.id.to_s },
        )
      end
    end

    context 'when workflow is started' do
      before do
        referral.workflow_engine.start_workflow!(user: hmis_user)
      end

      it 'shows first step as available' do
        _, result = post_graphql(**variables) { query }
        expect(response.status).to eq 200
        steps = result.dig('data', 'ceReferral', 'steps')

        expect(steps[0]['status']).to eq('available')
        expect(steps[1]['status']).to eq('unavailable')
      end
    end

    context 'when first step is completed' do
      before do
        referral.workflow_engine.start_workflow!(user: hmis_user)
        step = referral.workflow_engine.active_steps.first
        referral.workflow_engine.start_step!(step, user: hmis_user)
        referral.workflow_engine.complete_step!(step, user: hmis_user, submitted_values: { accepted: true })
      end

      it 'shows second step as available' do
        _, result = post_graphql(**variables) { query }
        expect(response.status).to eq 200
        steps = result.dig('data', 'ceReferral', 'steps')

        expect(steps[0]['status']).to eq('completed')
        expect(steps[1]['status']).to eq('available')
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
