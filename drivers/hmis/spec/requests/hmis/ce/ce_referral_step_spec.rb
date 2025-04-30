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

    it 'returns expected structure with swimlane' do
      step = referral.workflow_instance.steps.sole
      variables = {
        id: step.id,
      }
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
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
