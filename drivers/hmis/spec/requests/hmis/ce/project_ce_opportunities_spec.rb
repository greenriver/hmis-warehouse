###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require_relative '../../../support/ce_spec_helper'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'ce spec helper'

  before(:each) do
    hmis_login(user)
  end

  describe 'project ceOpportunities query' do
    let(:query) do
      <<~GRAPHQL
        query GetProjectCeOpportunities($id: ID!, $limit: Int = 25, $offset: Int = 0, $filters: ProjectCeOpportunityFilterOptions = null) {
          project(id: $id) {
            id
            ceOpportunities(limit: $limit, offset: $offset, filters: $filters) {
              offset
              limit
              nodesCount
              nodes {
                id
                name
                categories
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

    it "returns the project's opportunities" do
      response, result = post_graphql(**variables) { query }
      expect(response.status).to eq(200), result.inspect

      opportunities = result.dig('data', 'project', 'ceOpportunities', 'nodes')
      expect(opportunities.count).to eq(1)

      returned_opportunity = opportunities[0]
      expect(returned_opportunity['id']).to eq(opportunity.id.to_s)
    end

    it 'returns empty when user lacks permission' do
      remove_permissions(ds_access_control, :can_view_units)
      response, result = post_graphql(**variables) { query }
      expect(response.status).to eq(200), result.inspect
      expect(result.dig('data', 'project', 'ceOpportunities', 'nodes')).to be_empty
    end

    context 'when filtering for opportunities with open referrals' do
      let(:variables) do
        {
          id: project.id,
          filters: {
            status: ['open'],
          },
        }
      end

      let(:opportunity) { create :hmis_ce_opportunity, project: project, data_source: ds1 }
      let(:closed_opportunity) { create :hmis_ce_opportunity, project: project, data_source: ds1, status: :closed }
      let(:locked_opportunity) { create :hmis_ce_opportunity, project: project, data_source: ds1, status: :locked }

      it 'returns only opportunities with active referrals' do
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect

        opportunities = result.dig('data', 'project', 'ceOpportunities', 'nodes')
        expect(opportunities.count).to eq(1)

        expect(opportunities).to contain_exactly(
          a_hash_including('id' => opportunity.id.to_s),
        )
      end

      context 'with many opportunities' do
        before do
          40.times do
            create :hmis_ce_opportunity, project: project, data_source: ds1
          end
        end

        it 'queries the db a reasonable amount' do
          expect do
            response, result = post_graphql(**variables) { query }
            expect(response.status).to eq(200), result.inspect
            expect(result.dig('data', 'project', 'ceOpportunities', 'nodesCount')).to eq(41)
          end.to make_database_queries(count: 15..20)
        end
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
