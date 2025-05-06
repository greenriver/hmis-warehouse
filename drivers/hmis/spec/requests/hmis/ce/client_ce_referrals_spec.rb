###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require_relative '../../../support/ce_spec_helper'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'ce spec helper'

  before(:all) do
    cleanup_test_environment
  end
  before(:each) do
    hmis_login(user)
  end

  let!(:other_project) { create(:hmis_hud_project, project_type: 2) }
  let!(:other_project_referral) { create(:hmis_ce_referral, project: other_project, client: client) }

  describe 'project ceReferrals query' do
    let(:query) do
      <<~GRAPHQL
        query GetClientCeReferrals($id: ID!, $limit: Int = 25, $offset: Int = 0, $filters: ClientCeReferralFilterOptions = null) {
          client(id: $id) {
            id
            ceReferrals(limit: $limit, offset: $offset, filters: $filters) {
              nodesCount
              nodes {
                id
              }
            }
          }
        }
      GRAPHQL
    end

    let(:variables) do
      {
        id: client.id,
      }
    end

    it "returns the client's referrals" do
      response, result = post_graphql(**variables) { query }
      expect(response.status).to eq(200), result.inspect

      referrals = result.dig('data', 'client', 'ceReferrals', 'nodes')
      expect(referrals.count).to eq(2)
      expect(referrals).to contain_exactly(
        a_hash_including('id' => referral.id.to_s),
        a_hash_including('id' => other_project_referral.id.to_s),
      )
    end

    context 'when filtering by project' do
      let(:variables) do
        {
          id: client.id,
          filters: {
            project: [project.id],
          },
        }
      end

      it 'returns only referrals for the specified project' do
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect

        referrals = result.dig('data', 'client', 'ceReferrals', 'nodes')
        expect(referrals.count).to eq(1)
        expect(referrals).to contain_exactly(a_hash_including('id' => referral.id.to_s))
      end
    end

    context 'when filtering by project type' do
      let(:variables) do
        {
          id: client.id,
          filters: {
            projectType: ['ES_NBN'], # project type 1
          },
        }
      end

      it 'returns only referrals for the specified project type' do
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect

        referrals = result.dig('data', 'client', 'ceReferrals', 'nodes')
        expect(referrals.count).to eq(1)
        expect(referrals).to contain_exactly(a_hash_including('id' => referral.id.to_s))
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
