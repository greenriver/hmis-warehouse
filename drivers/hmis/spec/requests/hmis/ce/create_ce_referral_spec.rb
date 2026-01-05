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
        :can_view_referrals,
        :can_view_prioritized_client_lists,
      ],
    )
  end

  before(:each) do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    hmis_login(user)
  end

  let!(:project) { create :hmis_hud_project, data_source: ds1 }
  let!(:template) { create :hmis_workflow_definition_template, status: 'published', data_source: ds1 }
  let!(:unit_group) { create :hmis_unit_group, project: project, workflow_template: template }
  let!(:unit) { create :hmis_unit, project: project, unit_group: unit_group }
  let!(:opportunity) { create :hmis_ce_opportunity, unit: unit }
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

      context 'if the opportunity lacks a workflow template' do
        let!(:unit_group) { create :hmis_unit_group, project: project, workflow_template: nil }
        let!(:unit) { create :hmis_unit, project: project, unit_group: unit_group }
        let!(:opportunity) { create :hmis_ce_opportunity, unit: unit }

        it 'raises an error' do
          expect do
            expect_gql_error post_graphql(**variables) { mutation }
          end.not_to change(Hmis::Ce::Referral, :count)
        end
      end

      context 'with default swimlane assignments' do
        let!(:case_manager_1) { create :hmis_user }
        let!(:case_manager_2) { create :hmis_user }
        let!(:provider_user) { create :hmis_user }
        let!(:provider_swimlane) { template.swimlanes.create!(name: 'Providers') }

        context 'assigned at the project level' do
          let!(:default_assignment_1) do
            create(:hmis_ce_default_swimlane_assignment, user: case_manager_1, swimlane: swimlane, owner: project)
          end
          let!(:default_assignment_2) do
            create(:hmis_ce_default_swimlane_assignment, user: case_manager_2, swimlane: swimlane, owner: project)
          end
          let!(:default_assignment_provider) do
            create(:hmis_ce_default_swimlane_assignment, user: provider_user, swimlane: provider_swimlane, owner: project)
          end

          it 'creates referral participants from project-level defaults' do
            expect do
              post_graphql(**variables) { mutation }
            end.to change(Hmis::Ce::ReferralParticipant, :count).by(3)

            referral = Hmis::Ce::Referral.last
            expect(referral.participants.pluck(:user_id, :swimlane_id)).to contain_exactly(
              [case_manager_1.id, swimlane.id],
              [case_manager_2.id, swimlane.id],
              [provider_user.id, provider_swimlane.id],
            )
          end
        end

        shared_examples 'creates participant from single assignment' do |owner_description|
          it "creates referral participant from #{owner_description}-level default" do
            expect do
              post_graphql(**variables) { mutation }
            end.to change(Hmis::Ce::ReferralParticipant, :count).by(1)

            referral = Hmis::Ce::Referral.last
            participant = referral.participants.first
            expect(participant.user).to eq(case_manager_1)
            expect(participant.swimlane).to eq(swimlane)
          end
        end

        context 'assigned at the unit group level' do
          let!(:default_assignment) do
            create(:hmis_ce_default_swimlane_assignment, user: case_manager_1, swimlane: swimlane, owner: unit_group)
          end

          include_examples 'creates participant from single assignment', 'unit group'
        end

        context 'assigned at the organization level' do
          let!(:default_assignment) do
            create(:hmis_ce_default_swimlane_assignment, user: case_manager_1, swimlane: swimlane, owner: project.organization)
          end

          include_examples 'creates participant from single assignment', 'organization'
        end

        context 'assigned at the data source level' do
          let!(:default_assignment) do
            create(:hmis_ce_default_swimlane_assignment, user: case_manager_1, swimlane: swimlane, owner: ds1)
          end

          include_examples 'creates participant from single assignment', 'data source'
        end

        context 'with assignments at multiple levels' do
          let!(:project_assignment) do
            create(:hmis_ce_default_swimlane_assignment, user: case_manager_1, swimlane: swimlane, owner: project)
          end
          let!(:unit_group_assignment) do
            create(:hmis_ce_default_swimlane_assignment, user: case_manager_1, swimlane: swimlane, owner: unit_group)
          end
          let!(:org_assignment) do
            create(:hmis_ce_default_swimlane_assignment, user: case_manager_2, swimlane: swimlane, owner: project.organization)
          end
          let!(:ds_assignment) do
            create(:hmis_ce_default_swimlane_assignment, user: provider_user, swimlane: provider_swimlane, owner: ds1)
          end

          it 'creates participants additively from all levels, deduplicating by user and swimlane' do
            expect do
              post_graphql(**variables) { mutation }
            end.to change(Hmis::Ce::ReferralParticipant, :count).by(3)

            referral = Hmis::Ce::Referral.last
            # case_manager_1 assigned from project/unit_group (deduplicated to one participant)
            # case_manager_2 assigned from organization
            # provider_user assigned from data source with different swimlane
            expect(referral.participants.pluck(:user_id, :swimlane_id)).to contain_exactly(
              [case_manager_1.id, swimlane.id],
              [case_manager_2.id, swimlane.id],
              [provider_user.id, provider_swimlane.id],
            )
          end
        end

        context 'with default assignment for an unrelated project' do
          let!(:other_project) { create :hmis_hud_project, data_source: ds1 }
          let!(:unrelated_assignment) do
            create(:hmis_ce_default_swimlane_assignment, user: case_manager_1, swimlane: swimlane, owner: other_project)
          end

          it 'does not create participants for unrelated projects' do
            expect do
              post_graphql(**variables) { mutation }
            end.not_to change(Hmis::Ce::ReferralParticipant, :count)
          end
        end

        context 'with soft-deleted default assignments' do
          let!(:default_assignment) do
            create(:hmis_ce_default_swimlane_assignment, user: case_manager_1, swimlane: swimlane, owner: project, deleted_at: Time.current)
          end

          it 'does not create participants for soft-deleted assignments' do
            expect do
              post_graphql(**variables) { mutation }
            end.not_to change(Hmis::Ce::ReferralParticipant, :count)
          end
        end
      end
    end
  end
end
