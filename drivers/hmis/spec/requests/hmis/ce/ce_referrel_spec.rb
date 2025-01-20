require 'rails_helper'
require_relative '../login_and_permissions'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  let!(:ds_access_control) do
    create_access_control(hmis_user, ds1, with_permission: [:can_view_clients, :can_view_project, :can_view_enrollment_details])
  end

  before(:each) do
    hmis_login(user)
  end

  let(:client) { create :hmis_hud_client_complete, data_source: ds1, user: u1 }
  let(:project) { create :hmis_hud_project, data_source: ds1, user: u1 }
  let(:opportunity) { create :hmis_ce_opportunity, project: project }
  let(:workflow_template) { opportunity.workflow_template }
  let(:workflow_instance) { workflow_template.instances.create! }

  # Create workflow template nodes
  let!(:start_event) do
    create(
      :hmis_workflow_definition_start_event,
      template: workflow_template,
      name: 'Start Referral',
      trigger_config: [
        {
          event: 'start_workflow',
          message: 'start_referral',
        },
      ],
    )
  end

  let!(:case_manager_swimlane) { workflow_template.swimlanes.create!(name: 'Case Managers') }

  let!(:client_acceptance_task) do
    create(
      :hmis_workflow_definition_task,
      template: workflow_template,
      name: 'Client Acceptance',
      swimlane: case_manager_swimlane,
      form_definition: create(:hmis_form_definition),
    )
  end

  let!(:provider_acceptance_task) do
    create(
      :hmis_workflow_definition_task,
      template: workflow_template,
      name: 'Provider Acceptance',
      swimlane: case_manager_swimlane,
      form_definition: create(:hmis_form_definition),
    )
  end

  let!(:end_event) do
    create(
      :hmis_workflow_definition_end_event,
      template: workflow_template,
      name: 'Complete Referral',
      trigger_config: [
        {
          event: 'end_workflow',
          message: 'complete_referral',
        },
      ],
    )
  end

  # Connect the workflow nodes
  before do
    start_event.connect_to!(client_acceptance_task)
    client_acceptance_task.connect_to!(provider_acceptance_task)
    provider_acceptance_task.connect_to!(end_event)
  end

  let!(:referral) do
    create(
      :hmis_ce_referral,
      opportunity: opportunity,
      workflow_instance: workflow_instance,
      client: client,
      referred_by: hmis_user,
    )
  end

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
