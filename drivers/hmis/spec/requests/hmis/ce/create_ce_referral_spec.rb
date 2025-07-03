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
        :can_view_project,
        :can_view_units,
        :can_start_referrals,
      ],
    )
  end

  before(:each) do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    hmis_login(user)
  end

  let!(:project) { create :hmis_hud_project, data_source: ds1 }
  let!(:template) { create :hmis_workflow_definition_template, status: 'published', data_source: ds1 }
  let!(:opportunity) { create :hmis_ce_opportunity, project: project, workflow_template: template }
  let!(:client) { create :hmis_hud_client, data_source: ds1 }
  let!(:swimlane) { template.swimlanes.create!(name: 'Case Managers') }

  describe 'create referral mutation' do
    let(:mutation) do
      <<~GRAPHQL
        mutation CreateReferral($opportunityId: ID!, $clientId: ID, $sourceEnrollmentId: ID) {
          createCeReferral(opportunityId: $opportunityId, clientId: $clientId, sourceEnrollmentId: $sourceEnrollmentId) {
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

    describe 'when passing client id' do
      let(:variables) do
        {
          opportunityId: opportunity.id,
          clientId: client.id,
        }
      end

      context 'with valid input' do
        it 'creates a new referral' do
          expect do
            post_graphql(**variables) { mutation }
          end.to change(Hmis::Ce::Referral, :count).by(1)
        end

        it 'returns the created referral with steps' do
          expect do
            response, result = post_graphql(**variables) { mutation }
            expect(response.status).to eq(200), result.inspect

            referral_data = result.dig('data', 'createCeReferral', 'referral')

            expect(referral_data['status']).to eq('initialized')
            expect(referral_data['opportunity']).to include(
              'id' => opportunity.id.to_s,
              'name' => opportunity.name,
            )
            expect(referral_data['steps']).to be_an(Array)
          end.to change(Hmis::WorkflowExecution::Instance, :count).by(1)

          instance = Hmis::WorkflowExecution::Instance.last
          expect(instance.template).to eq(template)
        end
      end

      context 'when passed a source enrollment id' do
        let!(:enrollment) { create :hmis_hud_enrollment, client: client, data_source: ds1 }

        let(:variables) do
          {
            opportunityId: opportunity.id,
            sourceEnrollmentId: enrollment.id,
          }
        end

        it 'creates the referral using the source enrollment' do
          expect do
            response, result = post_graphql(**variables) { mutation }
            expect(response.status).to eq(200), result.inspect
          end.to change(Hmis::Ce::Referral, :count).by(1)

          referral = Hmis::Ce::Referral.last
          expect(referral.client).to eq(client)
          expect(referral.source_enrollment).to eq(enrollment)
        end
      end

      context 'when neither client nor source enrollment id is passed' do
        let(:variables) do
          {
            opportunityId: opportunity.id,
          }
        end

        it 'raises an error' do
          expect do
            expect_gql_error post_graphql(**variables) { mutation }
          end.not_to change(Hmis::Ce::Referral, :count)
        end
      end

      context 'if the client is in a different data source' do
        let!(:ds2) { create :hmis_data_source }
        let!(:client) { create :hmis_hud_client, data_source: ds2 }

        it 'raises an error' do
          expect do
            expect_gql_error post_graphql(**variables) { mutation }
          end.not_to change(Hmis::Ce::Referral, :count)
        end
      end

      context 'if the user lacks permission' do
        before do
          remove_permissions(ds_access_control, :can_start_referrals)
        end

        it 'raises an error' do
          expect do
            expect_gql_error post_graphql(**variables) { mutation }
          end.not_to change(Hmis::Ce::Referral, :count)
        end
      end
    end
  end
end
