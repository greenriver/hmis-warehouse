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
        :can_manage_units,
      ],
    )
  end

  before(:each) do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    hmis_login(user)
  end

  let(:project) { create :hmis_hud_project, data_source: ds1 }
  let(:workflow_template) { create :hmis_workflow_definition_template, status: 'published', data_source: ds1 }

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
      it 'returns the created opportunity' do
        expect do
          response, result = post_graphql(**variables) { mutation }
          expect(response.status).to eq(200), result.inspect
          opportunity_data = result.dig('data', 'createCeOpportunity', 'opportunity')

          expect(opportunity_data).to include(
            'name' => 'Housing Opportunity #1',
            'status' => 'open',
          )

          opportunity_id = result.dig('data', 'createCeOpportunity', 'opportunity', 'id')
          opportunity = Hmis::Ce::Opportunity.find(opportunity_id)

          expect(opportunity.project).to eq(project)
          expect(opportunity.workflow_template).to eq(workflow_template)
        end.to change(Hmis::Ce::Opportunity, :count).by(1)
      end
    end
  end
end
