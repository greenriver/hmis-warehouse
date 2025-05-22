# frozen_string_literal: true

require_relative '../../../support/ce_spec_helper'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'ce spec helper'

  before(:each) do
    hmis_login(user)
  end

  describe 'ce_referral_step query' do
    let(:query) do
      <<~GRAPHQL
        query GetCeReferralStep($id: ID!) {
          ceReferralStep(id: $id) {
            id
            stepId
            swimlane
            assignees {
              id
              name
            }
          }
        }
      GRAPHQL
    end

    before do
      referral.workflow_engine.start_workflow!(user: hmis_user)
    end

    let!(:assignee) { referral.workflow_instance.steps.sole.assignments.create(user: hmis_user) }

    let(:step) { referral.workflow_instance.steps.sole }
    let(:variables) do
      {
        id: step.id,
      }
    end

    it 'returns expected structure with swimlane' do
      response, result = post_graphql(**variables) { query }
      expect(response.status).to eq(200), result.inspect
      step_data = result.dig('data', 'ceReferralStep')
      expect(step_data.dig('stepId')).to eq(step.id.to_s)
      expect(step_data.dig('swimlane')).to eq(case_manager_swimlane.name)
      expect(step_data.dig('assignees')).to contain_exactly(
        a_hash_including(
          'id' => assignee.user.id.to_s,
        ),
      )
    end

    it 'returns nil when the user does not have permission' do
      remove_permissions(ds_access_control, :can_view_referrals)
      expect_gql_error(post_graphql(**variables) { query }, message: 'access denied')
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
