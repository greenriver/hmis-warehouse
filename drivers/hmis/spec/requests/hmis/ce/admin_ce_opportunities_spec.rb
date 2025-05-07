# frozen_string_literal: true

require_relative '../../../support/ce_spec_helper'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'ce spec helper'

  before(:each) do
    hmis_login(user)
  end

  describe 'admin ceOpportunities query' do
    let(:query) do
      <<~GRAPHQL
        query GetCeOpportunities($limit: Int = 25, $offset: Int = 0, $filters: CeOpportunityFilterOptions = null, $sortOrder: CeOpportunitySortOption = null) {
          ceOpportunities(limit: $limit, offset: $offset, filters: $filters, sortOrder: $sortOrder) {
            offset
            limit
            nodesCount
            nodes {
              id
              name
              categories
              status
              active
              expiresAt
              projectId
              projectName
              projectType
              organizationName
              dateAvailable
              unit {
                id
                name
              }
            }
          }
        }
      GRAPHQL
    end

    context 'when querying for opportunities' do
      let(:today) { Date.current }
      let!(:opportunity) { create :hmis_ce_opportunity, project: project, created_at: today }
      let!(:opportunity2) { create :hmis_ce_opportunity, project: project, created_at: today - 1.day }
      let!(:opportunity3) { create :hmis_ce_opportunity, project: project, created_at: today - 2.days }

      it 'default sorts by date available' do
        response, result = post_graphql { query }
        expect(response.status).to eq(200), result.inspect

        opportunities = result.dig('data', 'ceOpportunities', 'nodes')
        expect(opportunities.dig(0, 'id')).to eq(opportunity3.id.to_s)
        expect(opportunities.dig(1, 'id')).to eq(opportunity2.id.to_s)
        expect(opportunities.dig(2, 'id')).to eq(opportunity.id.to_s)
      end
    end

    context 'with many opportunities' do
      before do
        40.times do
          project = create :hmis_hud_project, data_source: ds1
          create :hmis_ce_opportunity, project: project
        end
      end

      it 'queries the db a reasonable amount' do
        expect do
          response, result = post_graphql { query }
          expect(response.status).to eq(200), result.inspect
          expect(result.dig('data', 'ceOpportunities', 'nodesCount')).to eq(41)
        end.to make_database_queries(count: 7..12)
      end
    end
  end
end
