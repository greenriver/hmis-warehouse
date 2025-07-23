# frozen_string_literal: true

require 'rails_helper'
require_relative '../login_and_permissions'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  before(:each) do
    hmis_login(user)
    # Enable CE configuration for these tests
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
  end

  describe 'direct_referral_form query' do
    let(:query) do
      <<~GRAPHQL
        query GetDirectReferralFormDefinition($targetUnitGroupId: ID!) {
          directReferralFormDefinition(targetUnitGroupId: $targetUnitGroupId) {
            id
          }
        }
      GRAPHQL
    end

    let!(:source_project) { create(:hmis_hud_project, data_source: ds1, organization: o1, user: u1) }
    let!(:target_project) { create(:hmis_hud_project, data_source: ds1, organization: o1, user: u1) }
    let!(:workflow_template) { create(:hmis_workflow_definition_template, data_source: ds1, template_type: 'ce_referral', status: 'published') }
    let!(:form_definition) { create(:hmis_form_definition) }

    let!(:initiation_task) do
      create(
        :hmis_workflow_definition_user_task,
        template: workflow_template,
        name: 'Direct Referral Initiation',
        form_definition: form_definition,
      )
    end

    let!(:unit_group) { create(:hmis_unit_group, project: target_project, workflow_template: workflow_template, direct_referral_entrypoint: initiation_task) }

    let!(:project_ce_config) { create(:hmis_project_ce_config, project: target_project, accepts_direct_referrals: true) }

    let!(:access_control) { create_access_control(hmis_user, source_project) }

    let(:variables) do
      {
        target_unit_group_id: unit_group.id,
      }
    end

    it 'returns the form definition for direct referral' do
      response, result = post_graphql(**variables) { query }
      expect(response.status).to eq(200), result.inspect

      form_data = result.dig('data', 'directReferralFormDefinition')
      expect(form_data).not_to be_nil
      expect(form_data['id']).to eq(form_definition.id.to_s)
    end

    context 'when target project does not accept direct referrals' do
      let!(:project_ce_config) { create(:hmis_project_ce_config, project: target_project, accepts_direct_referrals: false) }

      it 'raises access denied error' do
        expect_gql_error(post_graphql(**variables) { query }, message: 'access denied')
      end
    end

    context 'when specified unit group does not have a workflow template' do
      let!(:unit_group) { create(:hmis_unit_group, project: target_project, workflow_template: nil) }

      it 'raises API error' do
        expect_gql_error(post_graphql(**variables) { query }, message: 'Workflow template invalid or not found')
      end
    end

    context 'when no direct referral entrypoint is configured' do
      let!(:unit_group) { create(:hmis_unit_group, project: target_project, workflow_template: workflow_template, direct_referral_entrypoint: nil) }

      it 'raises API error' do
        expect_gql_error(post_graphql(**variables) { query }, message: 'Direct referral entrypoint invalid or not found')
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
