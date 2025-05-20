# frozen_string_literal: true

require 'rails_helper'
require_relative '../login_and_permissions'
require_relative '../../../support/ce_spec_helper'

RSpec.describe Mutations::Ce::SubmitCeReferralStep, type: :request do
  include_context 'ce spec helper'

  before(:each) do
    hmis_login(user)
  end

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

  let!(:ds_access_control) do
    create_access_control(
      hmis_user,
      ds1,
      with_permission: [:can_view_project, :can_view_referrals, :can_perform_any_referral_tasks],
    )
  end

  describe 'submit step mutation' do
    let!(:other_user) { create(:user, first_name: 'someone', last_name: 'else') }
    let!(:other_hmis_user) { other_user.related_hmis_user(ds1) }

    before(:each) do
      engine.start_workflow!(user: other_hmis_user)
      step = engine.active_steps.first
      engine.start_step!(step, user: other_hmis_user)
    end

    let(:mutation) do
      <<~GRAPHQL
        mutation SubmitCeReferralStep(
          $referralId: ID!
          $stepId: ID!
          $input: JsonObject!
          $confirmed: Boolean
          $formDefinitionId: ID!
        ) {
          submitCeReferralStep(
            referralId: $referralId
            stepId: $stepId
            input: $input
            confirmed: $confirmed
            formDefinitionId: $formDefinitionId
          ) {
            step {
              id
              name
              status
              formDefinition {
                id
              }
              swimlane
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
        formDefinitionId: ce_step_definition.id,
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

      context 'with permission' do
        it 'submits the step' do
          response, result = post_graphql(**variables) { mutation }
          expect(response.status).to eq(200), result&.inspect
          step_data = result.dig('data', 'submitCeReferralStep', 'step')
          expect(step_data['name']).to eq('Client Acceptance')
          expect(step_data['status']).to eq('completed')
          expect(step_data['swimlane']).to eq(case_manager_swimlane.name)
          expect(step.reload.status).to eq('completed')
          expect(referral.reload.status).to eq('accepted')
        end
      end

      context 'without permission' do
        let!(:ds_access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_view_referrals, :can_view_project]) }

        it 'raises an error' do
          expect do
            expect_gql_error(post_graphql(**variables) { mutation }, message: 'access denied')
          end.to not_change(step, :status)
        end
      end

      context 'with permission on own tasks' do
        let!(:ds_access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_view_referrals, :can_perform_own_referral_tasks, :can_view_project]) }

        it 'raises an error' do
          expect_gql_error(post_graphql(**variables) { mutation }, message: 'access denied')
        end

        context 'and task assignment' do
          before do
            step.assignments.create!(user: hmis_user)
          end

          it 'submits the step' do
            expect do
              response, result = post_graphql(**variables) { mutation }
              expect(response.status).to eq(200), result.inspect
              step.reload
            end.to change(step, :status).to('completed')
          end
        end
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
