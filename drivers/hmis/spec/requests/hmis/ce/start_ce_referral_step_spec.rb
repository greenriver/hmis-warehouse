# frozen_string_literal: true

require 'rails_helper'
require_relative '../login_and_permissions'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Mutations::Ce::StartCeReferralStep, type: :request do
  include_context 'hmis base setup'

  before(:each) do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    hmis_login(user)
  end

  # Setup workflow template with nodes
  let(:project) { create :hmis_hud_project, data_source: ds1 }
  let(:template) { create :hmis_workflow_definition_template, status: 'published', data_source: ds1 }
  let(:swimlane) { template.swimlanes.create!(name: 'Case Managers') }

  # Create workflow nodes
  let!(:start_event) do
    create(
      :hmis_workflow_definition_start_event,
      template: template,
      name: 'Start Referral',
      trigger_config: [
        {
          event: 'start_workflow',
          message: 'start_referral',
        },
      ],
    )
  end

  let!(:client_acceptance_task) do
    create(
      :hmis_workflow_definition_task,
      template: template,
      name: 'Client Acceptance',
      swimlane: swimlane,
    )
  end

  # Connect workflow nodes
  before do
    start_event.connect_to!(client_acceptance_task)
  end

  # Create opportunity and referral
  let(:opportunity) { create :hmis_ce_opportunity, project: project, workflow_template: template }
  let(:client) { create :hmis_hud_client, data_source: ds1 }
  let(:workflow_instance) { template.instances.create! }
  let!(:referral) do
    create(
      :hmis_ce_referral,
      opportunity: opportunity,
      workflow_instance: workflow_instance,
      data_source: ds1,
      client: client,
      referred_by: hmis_user,
    )
  end

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
              swimlane
              assignees {
                id
                name
              }
            }
          }
        }
      GRAPHQL
    end

    before do
      # Start the workflow to make the first step available
      referral.workflow_engine.start_workflow!(user: hmis_user)
    end

    let(:step) { referral.workflow_engine.active_steps.first }

    let(:variables) do
      {
        referralId: referral.id,
        stepId: step.id,
      }
    end

    context 'when the user has access' do
      let!(:ds_access_control) do
        create_access_control(
          hmis_user,
          ds1,
          with_permission: [
            :can_view_project,
            :can_view_referrals,
            :can_perform_any_referral_tasks,
          ],
        )
      end

      it 'starts the step' do
        expect do
          response, result = post_graphql(**variables) { mutation }
          expect(response.status).to eq(200), result.inspect

          step_data = result.dig('data', 'startCeReferralStep', 'step')
          expect(step_data['status']).to eq('in_progress')
          expect(step_data['name']).to eq('Client Acceptance')
          expect(step_data.dig('swimlane')).to eq(swimlane.name)
          expect(step_data['assignees']).to contain_exactly(
            a_hash_including('id' => hmis_user.id.to_s, 'name' => hmis_user.name),
          )
          expect(step_data['formDefinition']['id']).to eq(client_acceptance_task.form_definitions.sole.id.to_s)

          step.reload
        end.to change(step, :status).to('in_progress').
          and change(step, :started_at).from(nil).
          and change(Hmis::WorkflowExecution::AuditEvent, :count).by(1).
          and change(step.assignments, :count).by(1)

        audit_event = Hmis::WorkflowExecution::AuditEvent.last
        expect(audit_event.event_type).to eq('start_step')
        expect(audit_event.user).to eq(hmis_user)
        expect(audit_event.step).to eq(step)
      end
    end

    context 'when the user does not have access' do
      let!(:ds_access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_view_referrals, :can_view_project]) }

      it 'raises an error' do
        expect_gql_error(post_graphql(**variables) { mutation }, message: 'access denied')
      end

      context 'when the user has can_perform_own_referral_tasks' do
        let!(:ds_access_control) do
          create_access_control(
            hmis_user,
            ds1,
            with_permission: [:can_view_referrals, :can_perform_own_referral_tasks, :can_view_project],
          )
        end

        it 'raises an error if the user is not assigned the task' do
          expect_gql_error(post_graphql(**variables) { mutation }, message: 'access denied')
        end

        context 'when the user is assigned to the task' do
          before do
            step.assignments.create!(user: hmis_user)
          end

          it 'starts the step' do
            expect do
              response, result = post_graphql(**variables) { mutation }
              expect(response.status).to eq(200), result.inspect
              step.reload
            end.to change(step, :status).to('in_progress')
          end
        end
      end
    end
  end
end
