# frozen_string_literal: true

require 'rails_helper'
require_relative '../login_and_permissions'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Mutations::Ce::CreateCeReferral, type: :request do
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
  let(:template) { create :hmis_workflow_definition_template, status: 'published' }
  let(:opportunity) { create :hmis_ce_opportunity, project: project, workflow_template: template }
  let(:client) { create :hmis_hud_client, data_source: ds1 }
  let(:swimlane) { template.swimlanes.create!(name: 'Case Managers') }

  describe 'create referral mutation' do
    let(:mutation) do
      <<~GRAPHQL
        mutation CreateReferral($opportunityId: ID!, $clientId: ID!, $input: CeReferralInput!) {
          createCeReferral(opportunityId: $opportunityId, clientId: $clientId, input: $input) {
            errors {
              message
              attribute
              fullMessage
            }
            referral {
              id
              status
              opportunity {
                id
                name
              }
              steps {
                id
                name
                status
              }
            }
          }
        }
      GRAPHQL
    end

    let(:variables) do
      {
        opportunityId: opportunity.id,
        clientId: client.id,
        input: {
          participants: {
            userId: hmis_user.id,
            swimlaneId: swimlane.id,
          },
        },
      }
    end

    context 'with valid input' do
      it 'creates a new referral' do
        expect do
          post_graphql(**variables) { mutation }
        end.to change(Hmis::Ce::Referral, :count).by(1)
      end

      it 'returns the created referral with steps' do
        _, result = post_graphql(**variables) { mutation }
        referral_data = result.dig('data', 'createCeReferral', 'referral')

        expect(referral_data['status']).to eq('initialized')
        expect(referral_data['opportunity']).to include(
          'id' => opportunity.id.to_s,
          'name' => opportunity.name,
        )
        expect(referral_data['steps']).to be_an(Array)
      end

      it 'creates referral participants' do
        expect do
          post_graphql(**variables) { mutation }
        end.to change(Hmis::Ce::ReferralParticipant, :count).by(1)

        participant = Hmis::Ce::ReferralParticipant.last
        expect(participant.user).to eq(hmis_user)
        expect(participant.swimlane).to eq(swimlane)
      end

      it 'creates a workflow instance' do
        expect do
          post_graphql(**variables) { mutation }
        end.to change(Hmis::WorkflowExecution::Instance, :count).by(1)

        instance = Hmis::WorkflowExecution::Instance.last
        expect(instance.template).to eq(template)
      end
    end
  end
end
