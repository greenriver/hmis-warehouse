# frozen_string_literal: true

require 'rails_helper'
require_relative '../login_and_permissions'
require_relative './ce_spec_helper'

RSpec.describe Mutations::CeReferralStepStart, type: :request do
  include_context 'ce spec helper'

  describe 'start step mutation' do
    let(:mutation) do
      <<~GRAPHQL
        mutation StartStep($referralId: ID!, $stepId: ID!) {
          startCeReferralStep(referralId: $referralId, stepId: $stepId) {
            errors {
              message
              attribute
              fullMessage
            }
            step {
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

    context 'with valid input' do
      before do
        # Start the workflow to make the first step available
        engine.start_workflow!(user: hmis_user)
      end

      let(:step) { engine.active_steps.first }

      let(:variables) do
        {
          referralId: referral.id,
          stepId: step.id,
        }
      end

      it 'starts the step' do
        _, result = post_graphql(**variables) { mutation }
        step_data = result.dig('data', 'startCeReferralStep', 'step')

        expect(step_data['status']).to eq('in_progress')
        expect(step_data['name']).to eq('Client Acceptance')
        expect(step.reload.status).to eq('in_progress')
      end

      it 'includes form definition in response' do
        _, result = post_graphql(**variables) { mutation }
        step_data = result.dig('data', 'startCeReferralStep', 'step')

        expect(step_data['formDefinition']['id']).to eq(client_acceptance_task.form_definition.id.to_s)
      end

      it 'creates an audit event' do
        expect do
          post_graphql(**variables) { mutation }
        end.to change(Hmis::WorkflowExecution::AuditEvent, :count).by(1)

        audit_event = Hmis::WorkflowExecution::AuditEvent.last
        expect(audit_event.event_type).to eq('start_step')
        expect(audit_event.user).to eq(hmis_user)
        expect(audit_event.step).to eq(step)
      end
    end
  end
end
