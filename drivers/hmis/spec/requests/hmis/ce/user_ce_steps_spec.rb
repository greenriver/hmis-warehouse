###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../login_and_permissions'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  let!(:project) { create(:hmis_hud_project, data_source: ds1) }
  let!(:referral) { create :hmis_ce_referral, project: project }
  let!(:step1) { create :hmis_wfe_step, instance: referral.workflow_instance, assignees: [hmis_user] }
  let!(:step2) { create :hmis_wfe_step, instance: referral.workflow_instance, assignees: [hmis_user] }

  # Steps that shouldn't be resolved
  let!(:hmis_user2) { create(:hmis_user) }
  let!(:other_user_step) { create :hmis_wfe_step, instance: referral.workflow_instance, assignees: [hmis_user2] }
  let!(:closed_step) { create :hmis_wfe_step, instance: referral.workflow_instance, assignees: [hmis_user], status: 'completed' }
  let!(:non_ce_template) { create(:hmis_workflow_definition_template, template_type: 'not_ce', data_source: ds1) }
  let!(:non_ce_instance) { create(:hmis_workflow_execution_instance, template: non_ce_template) }
  let!(:non_ce_step) { create :hmis_wfe_step, instance: non_ce_instance, assignees: [hmis_user] }

  let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_view_project, :can_view_referrals, :can_perform_own_referral_tasks]) }

  before(:each) do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    hmis_login(user)
  end

  describe 'user dashboard CE steps query' do
    let(:query) do
      <<~GRAPHQL
        query GetCeAssignedSteps {
          userDashboard {
            ceReferralSteps {
              nodesCount
              nodes {
                stepId
                referral {
                  id
                  targetProjectId
                }
              }
            }
          }
        }
      GRAPHQL
    end

    it 'resolves CE steps assigned to the user' do
      response, result = post_graphql(id: hmis_user.id) { query }
      expect(response.status).to eq(200), result.inspect
      steps = result.dig('data', 'userDashboard', 'ceReferralSteps', 'nodes')
      expect(steps.count).to eq(2)
      expect(steps).to contain_exactly(
        a_hash_including(
          'stepId' => step1.id.to_s,
          'referral' => {
            'id' => referral.id.to_s,
            'targetProjectId' => referral.target_project.id.to_s,
          },
        ),
        a_hash_including(
          'stepId' => step2.id.to_s,
          'referral' => {
            'id' => referral.id.to_s,
            'targetProjectId' => referral.target_project.id.to_s,
          },
        ),
      )
    end

    it 'resolves nothing when the user lacks permission' do
      remove_permissions(access_control, :can_view_project, :can_view_referrals)
      response, result = post_graphql(id: hmis_user.id) { query }
      expect(response.status).to eq(200), result.inspect
      steps = result.dig('data', 'userDashboard', 'ceReferralSteps', 'nodes')
      expect(steps.count).to eq(0)
    end

    context 'with many assigned steps' do
      before do
        50.times do
          project = create :hmis_hud_project, data_source: ds1
          new_referral = create :hmis_ce_referral, project: project
          create :hmis_wfe_step, instance: new_referral.workflow_instance, assignees: [hmis_user]
        end
      end

      it 'does not cause n+1' do
        expect do
          response, result = post_graphql(id: hmis_user.id) { query }
          expect(response.status).to eq(200), result.inspect
          expect(result.dig('data', 'userDashboard', 'ceReferralSteps', 'nodesCount')).to eq(52)
        end.to make_database_queries(count: 15..25)
      end
    end
  end
end
