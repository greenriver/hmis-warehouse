# frozen_string_literal: true

require 'rails_helper'
require_relative '../login_and_permissions'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Mutations::Ce::StartCeReferralStep, type: :request do
  include_context 'hmis base setup'

  let!(:ds_access_control) do
    create_access_control(
      hmis_user,
      ds1,
      with_permission: [
        :can_view_clients,
        :can_view_project,
        :can_edit_project_details,
      ],
    )
  end

  before(:each) do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    hmis_login(user)
  end

  # Setup workflow template with nodes
  let(:project) { create :hmis_hud_project, data_source: ds1 }
  let(:template) { create :hmis_workflow_definition_template, status: 'published' }
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
              swimlane {
                id
                name
                participants {
                  id
                  name
                }
              }
              assignees {
                id
                name
              }
            }
          }
        }
      GRAPHQL
    end

    context 'with a workflow that has been started' do
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

      context 'with valid input' do
        let!(:participant) { referral.participants.create(swimlane: swimlane, user: hmis_user) }

        it 'starts the step' do
          _, result = post_graphql(**variables) { mutation }
          step_data = result.dig('data', 'startCeReferralStep', 'step')

          expect(step_data['status']).to eq('in_progress')
          expect(step_data['name']).to eq('Client Acceptance')
          expect(step_data.dig('swimlane', 'id')).to eq(swimlane.id.to_s)
          expect(step_data.dig('swimlane', 'participants', 0, 'id')).to eq(hmis_user.id.to_s)
          expect(step.reload.status).to eq('in_progress')
        end

        it 'assigns the user and returns the assignee' do
          _, result = post_graphql(**variables) { mutation }
          step_data = result.dig('data', 'startCeReferralStep', 'step')

          expect(step_data['assignees']).to contain_exactly(
            a_hash_including('id' => hmis_user.id.to_s, 'name' => hmis_user.name),
          )
          expect(step.reload.assignments.sole.user).to eq(hmis_user)
        end

        it 'includes form definition in response' do
          _, result = post_graphql(**variables) { mutation }
          step_data = result.dig('data', 'startCeReferralStep', 'step')

          expect(step_data['formDefinition']['id']).to eq(client_acceptance_task.form_definitions.sole.id.to_s)
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
end
