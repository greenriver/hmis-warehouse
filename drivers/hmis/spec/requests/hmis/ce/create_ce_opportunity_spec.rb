# frozen_string_literal: true

require 'rails_helper'
require_relative '../login_and_permissions'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Mutations::Ce::CreateCeOpportunity, type: :request do
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

  let(:project) { create :hmis_hud_project, data_source: ds1 }
  let(:workflow_template) { create :hmis_workflow_definition_template, status: 'published' }

  describe 'create opportunity mutation' do
    let(:mutation) do
      <<~GRAPHQL
        mutation CreateOpportunity($projectId: ID!, $input: CeOpportunityInput!) {
          createCeOpportunity(projectId: $projectId, input: $input) {
            errors {
              message
              attribute
              fullMessage
            }
            opportunity {
              id
              name
              status
            }
          }
        }
      GRAPHQL
    end

    let(:variables) do
      {
        projectId: project.id,
        input: {
          name: 'Housing Opportunity #1',
          templateId: workflow_template.id,
        },
      }
    end

    context 'with valid input' do
      it 'creates a new opportunity' do
        expect do
          post_graphql(**variables) { mutation }
        end.to change(Hmis::Ce::Opportunity, :count).by(1)
      end

      it 'returns the created opportunity' do
        _, result = post_graphql(**variables) { mutation }
        opportunity_data = result.dig('data', 'createCeOpportunity', 'opportunity')

        expect(opportunity_data).to include(
          'name' => 'Housing Opportunity #1',
          'status' => 'open',
        )
      end

      it 'associates opportunity with correct project and template' do
        _, result = post_graphql(**variables) { mutation }
        opportunity_id = result.dig('data', 'createCeOpportunity', 'opportunity', 'id')
        opportunity = Hmis::Ce::Opportunity.find(opportunity_id)

        expect(opportunity.project).to eq(project)
        expect(opportunity.workflow_template).to eq(workflow_template)
      end
    end
  end
end
