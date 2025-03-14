# frozen_string_literal: true

require 'rails_helper'
require_relative '../login_and_permissions'
require_relative './ce_spec_helper'

RSpec.describe Mutations::Ce::SubmitCeReferralStep, type: :request do
  include_context 'ce spec helper'

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

  describe 'submit step mutation' do
    before(:each) do
      engine.start_workflow!(user: hmis_user)
      step = engine.active_steps.first
      engine.start_step!(step, user: hmis_user)
    end

    let(:mutation) do
      <<~GRAPHQL
        mutation SubmitCeReferralStep(
          $referralId: ID!
          $stepId: ID!
          $input: JsonObject!
          $confirmed: Boolean
        ) {
          submitCeReferralStep(
            referralId: $referralId
            stepId: $stepId
            input: $input
            confirmed: $confirmed
          ) {
            step {
              id
              name
              status
              formDefinition {
                id
              }
            }
            referral {
              id
              status
            }
            #{error_fields}
          }
        }
      GRAPHQL
    end

    let(:step) { engine.active_steps.first }

    let(:base_variables) do
      {
        referralId: referral.id,
        stepId: step.id,
      }
    end

    context 'with valid input' do
      let(:variables) do
        {
          **base_variables,
          input: {
            contact_date: 1.day.ago,
            client_accepted: 1,
          }.stringify_keys,
        }
      end

      it 'submits the step' do
        response, result = post_graphql(**variables) { mutation }
        expect(response.status).to eq(200), result&.inspect
        step_data = result.dig('data', 'submitCeReferralStep', 'step')
        expect(step_data['name']).to eq('Client Acceptance')
        expect(step_data['status']).to eq('completed')
        expect(step.reload.status).to eq('completed')
        expect(referral.reload.status).to eq('accepted')
      end
    end

    context 'if the submission will reject the referral' do
      let(:variables) do
        {
          **base_variables,
          input: {
            contact_date: 1.day.ago,
            client_accepted: 0,
          }.stringify_keys,
        }
      end

      it 'returns a warning, then succeeds when confirmed flag is passed' do
        expect do
          response, result = post_graphql(**variables) { mutation }
          expect(response.status).to eq(200), result&.inspect
          errors = result.dig('data', 'submitCeReferralStep', 'errors')
          expect(errors.count).to eq(1)
          expect(errors.first['severity']).to eq('warning')
          expect(errors.first['fullMessage']).to eq('This will decline the referral')
          referral.reload
        end.to not_change(referral, :status)

        expect do
          response, result = post_graphql(**variables, confirmed: true) { mutation }
          expect(response.status).to eq(200), result&.inspect
          errors = result.dig('data', 'submitCeReferralStep', 'errors')
          expect(errors.count).to eq(0)
          referral_response = result.dig('data', 'submitCeReferralStep', 'referral')
          expect(referral_response['status']).to eq('rejected')
          referral.reload
        end.to change(referral, :status).from('in_progress').to('rejected')
      end
    end

    context 'with invalid input' do
      let(:variables) do
        {
          **base_variables,
          input: {
            contact_date: 1.day.ago,
            client_accepted: nil,
          }.stringify_keys,
        }
      end

      it 'returns validation errors' do
        expect do
          response, result = post_graphql(**variables, confirmed: true) { mutation }
          expect(response.status).to eq(200), result&.inspect
          errors = result.dig('data', 'submitCeReferralStep', 'errors')
          expect(errors.count).to eq(1)
          expect(errors.first['severity']).to eq('error')
          expect(errors.first['linkId']).to eq('client_accepted')
          expect(errors.first['message']).to eq('must exist')
          step.reload
        end.to not_change(step, :status)
      end
    end
  end
end
