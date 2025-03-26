# frozen_string_literal: true

#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

require_relative '../../../support/ce_spec_helper'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'ce spec helper'

  before(:each) do
    hmis_login(user)
  end

  describe 'project ceReferrals query' do
    let(:query) do
      <<~GRAPHQL
        query GetProjectCeReferrals($id: ID!, $limit: Int = 25, $offset: Int = 0, $filters: CeReferralFilterOptions = null) {
          project(id: $id) {
            id
            ceReferrals(limit: $limit, offset: $offset, filters: $filters) {
              offset
              limit
              nodesCount
              nodes {
                id
                status
                createdAt
                opportunity {
                  id
                  name
                }
                currentStepName
              }
            }
          }
        }
      GRAPHQL
    end

    let(:variables) do
      {
        id: project.id,
      }
    end

    it "returns the project's referrals" do
      response, result = post_graphql(**variables) { query }
      expect(response.status).to eq(200), result.inspect

      referrals = result.dig('data', 'project', 'ceReferrals', 'nodes')
      expect(referrals.count).to eq(1)

      returned_referral = referrals[0]
      expect(returned_referral['id']).to eq(referral.id.to_s)
      expect(returned_referral['status']).to eq('initialized')
    end

    context 'when filtering for active referrals' do
      let(:variables) do
        {
          id: project.id,
          filters: {
            status: ['initialized', 'in_progress'],
          },
        }
      end

      let!(:referral) { create(:hmis_ce_referral, project: project) }
      let!(:in_progress_referral) { create(:hmis_ce_referral, status: :in_progress, project: project) }
      let!(:accepted_referral) { create(:hmis_ce_referral, status: :accepted, project: project) }
      let!(:rejected_referral) { create(:hmis_ce_referral, status: :rejected, project: project) }

      it 'returns only active referrals' do
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect

        referrals = result.dig('data', 'project', 'ceReferrals', 'nodes')
        expect(referrals.count).to eq(2)

        expect(referrals).to contain_exactly(
          a_hash_including('id' => referral.id.to_s),
          a_hash_including('id' => in_progress_referral.id.to_s),
        )
      end

      context 'with many referrals' do
        before do
          30.times do
            in_progress_referral = create(:hmis_ce_referral, project: project, workflow_template: workflow_template)
            in_progress_referral.workflow_engine.start_workflow!(user: hmis_user) # start workflow so that it has a step in progress
          end
        end

        it 'queries the db a reasonable amount' do
          expect do
            response, result = post_graphql(**variables) { query }
            expect(response.status).to eq(200), result.inspect
            expect(result.dig('data', 'project', 'ceReferrals', 'nodesCount')).to eq(32)
          end.to make_database_queries(count: 15..20)
        end
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
