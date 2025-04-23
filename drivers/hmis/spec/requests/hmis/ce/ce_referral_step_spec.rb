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
        query GetCeReferralStep($id: ID!, $referralId: ID!) {
          ceReferralStep(id: $id, referralId: $referralId) {
            id
            stepId
            swimlane {
              id
              name
              participants {
                id
                name
              }
            }
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

    let!(:participant) { referral.participants.create(swimlane: case_manager_swimlane, user: hmis_user) }

    it 'returns expected structure with swimlane' do
      step = referral.workflow_instance.steps.sole
      variables = {
        id: step.id,
        referralId: referral.id,
      }
      response, result = post_graphql(**variables) { query }
      expect(response.status).to eq(200), result.inspect
      step_data = result.dig('data', 'ceReferralStep')
      expect(step_data.dig('stepId')).to eq(step.id.to_s)
      expect(step_data.dig('swimlane', 'id')).to eq(case_manager_swimlane.id.to_s)
      expect(step_data.dig('swimlane', 'participants', 0, 'id')).to eq(hmis_user.id.to_s)
      expect(step_data.dig('assignees')).to be_empty # this referral has potential participants but no direct assignees yet
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
