# frozen_string_literal: true

require 'rails_helper'
require_relative '../login_and_permissions'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  let!(:ds_access_control) do
    create_access_control(
      hmis_user, ds1,
      with_permission: [
        :can_view_clients,
        :can_view_project,
        :can_view_enrollment_details,
      ]
    )
  end

  before(:each) do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    hmis_login(user)
  end

  # Basic setup
  let(:project) { create :hmis_hud_project, data_source: ds1, user: u1 }
  let(:client) { create :hmis_hud_client, data_source: ds1 }

  # Create candidate pools with different criteria
  let!(:pool_veterans) do
    create(
      :hmis_ce_match_candidate_pool,
      requirement_expression: 'veteran_status = 1',
      priority_expression: 'current_age',
    )
  end

  let!(:pool_seniors) do
    create(
      :hmis_ce_match_candidate_pool,
      requirement_expression: 'current_age >= 65',
      priority_expression: 'current_age',
    )
  end

  # Create candidates linking client to pools
  let!(:veteran_candidate) do
    create(
      :hmis_ce_match_candidate,
      candidate_pool: pool_veterans,
      client: client,
      priority_score: 75,
    )
  end

  let!(:senior_candidate) do
    create(
      :hmis_ce_match_candidate,
      candidate_pool: pool_seniors,
      client: client,
      priority_score: 85,
    )
  end

  describe 'client query with opportunities' do
    # Create opportunities in different states
    let!(:opportunity_veterans) do
      create(
        :hmis_ce_opportunity,
        project: project,
        candidate_pool: pool_veterans,
        status: 'open',
      )
    end

    let!(:opportunity_seniors) do
      create(
        :hmis_ce_opportunity,
        project: project,
        candidate_pool: pool_seniors,
        status: 'open',
      )
    end

    let!(:closed_opportunity) do
      create(
        :hmis_ce_opportunity,
        project: project,
        candidate_pool: pool_veterans,
        status: 'closed',
      )
    end

    let(:query) do
      <<~GRAPHQL
        query GetClient($id: ID!) {
          client(id: $id) {
            id
            eligibleCeOpportunities {
              nodes {
                id
                name
                status
                expiresAt
                candidates {
                  nodes {
                    id
                    priorityScore
                    client {
                      id
                    }
                  }
                }
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

    context 'when client has matching opportunities' do
      it 'returns expected client information' do
        _, result = post_graphql(**variables) { query }
        client_data = result.dig('data', 'client')

        expect(client_data).to include('id' => client.id.to_s)

        opportunities = result.dig('data', 'client', 'eligibleCeOpportunities', 'nodes')

        expect(opportunities).to be_an(Array)
        expect(opportunities.length).to eq(2) # Should only include open opportunities

        opportunity_ids = opportunities.map { |o| o['id'] }
        expect(opportunity_ids).to include(
          opportunity_veterans.id.to_s,
          opportunity_seniors.id.to_s,
        )
        expect(opportunity_ids).not_to include(closed_opportunity.id.to_s)

        first_opportunity = opportunities.first
        expect(first_opportunity['candidates']['nodes']).to be_an(Array)
        expect(first_opportunity['candidates']['nodes'].first).to include(
          'priorityScore' => kind_of(Integer),
          'client' => { 'id' => client.id.to_s },
        )
      end
    end

    context 'when client has an active referral' do
      let!(:active_referral) do
        create(
          :hmis_ce_referral,
          opportunity: opportunity_veterans,
          client: client,
          status: 'in_progress',
        )
      end

      it 'excludes the opportunity with active referral' do
        _, result = post_graphql(**variables) { query }
        opportunities = result.dig('data', 'client', 'eligibleCeOpportunities', 'nodes')

        opportunity_ids = opportunities.map { |o| o['id'] }
        expect(opportunity_ids).not_to include(opportunity_veterans.id.to_s)
        expect(opportunities.length).to eq(1) # Should only include opportunity_seniors
      end
    end

    context 'when client has overlapping opportunity categories' do
      let!(:category) { create(:hmis_ce_opportunity_category, name: 'Housing') }

      before do
        opportunity_veterans.categories << category
        opportunity_seniors.categories << category
      end

      let!(:active_referral) do
        create(
          :hmis_ce_referral,
          opportunity: opportunity_veterans,
          client: client,
          status: 'in_progress',
        )
      end

      it 'excludes opportunities with overlapping categories when client has active referral' do
        _, result = post_graphql(**variables) { query }
        opportunities = result.dig('data', 'client', 'eligibleCeOpportunities', 'nodes')

        expect(opportunities).to be_empty # Both should be excluded due to category overlap
      end
    end

    context 'when client has no matching opportunities' do
      let(:client_without_matches) { create :hmis_hud_client, data_source: ds1 }

      let(:no_match_variables) do
        {
          id: client_without_matches.id,
        }
      end

      it 'returns an empty opportunities array' do
        _, result = post_graphql(**no_match_variables) { query }
        opportunities = result.dig('data', 'client', 'eligibleCeOpportunities', 'nodes')

        expect(opportunities).to be_an(Array)
        expect(opportunities).to be_empty
      end
    end
  end

  describe 'client eligible CE opportunities query with filters' do
    let(:query) do
      <<~GRAPHQL
        query GetClient($id: ID!, $filters: ClientEligibleCeOpportunityFilterOptions) {
          client(id: $id) {
            id
            eligibleCeOpportunities(filters: $filters) {
              nodesCount
              nodes {
                id
                candidatesGeneratedAt
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

    let(:p1) { create :hmis_hud_project, project_type: 1, data_source: ds1, user: u1 }
    let(:p2) { create :hmis_hud_project, project_type: 1, data_source: ds1, user: u1 }
    let(:p3) { create :hmis_hud_project, project_type: 5, data_source: ds1, user: u1 }
    let!(:opportunity1) { create(:hmis_ce_opportunity, project: p1, candidate_pool: pool_veterans) }
    let!(:opportunity2) { create(:hmis_ce_opportunity, project: p2, candidate_pool: pool_veterans) }
    let!(:opportunity3) { create(:hmis_ce_opportunity, project: p3, candidate_pool: pool_veterans) }

    context 'when project ID filter is passed' do
      let(:variables) do
        {
          id: client.id,
          filters: {
            project: [p1.id], # project type 1
          },
        }
      end
      it 'returns only opportunities for that project' do
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect
        opportunities = result.dig('data', 'client', 'eligibleCeOpportunities', 'nodes')
        expect(opportunities.length).to eq(1)
        expect(opportunities).to contain_exactly(
          a_hash_including('id' => opportunity1.id.to_s),
        )
      end
    end

    context 'when project type filter is passed' do
      let(:variables) do
        {
          id: client.id,
          filters: {
            project_type: ['ES_NBN'], # project type 1
          },
        }
      end
      it 'returns only opportunities for that project type' do
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect
        opportunities = result.dig('data', 'client', 'eligibleCeOpportunities', 'nodes')
        expect(opportunities.length).to eq(2)
        expect(opportunities).to contain_exactly(
          a_hash_including('id' => opportunity1.id.to_s),
          a_hash_including('id' => opportunity2.id.to_s),
        )
      end

      context 'when there are many opportunities' do
        before do
          opportunities = 30.times.map do
            build(:hmis_ce_opportunity, project: p1, candidate_pool: pool_veterans)
          end
          Hmis::Ce::Opportunity.import!(opportunities)
        end

        it 'makes a reasonable number of db queries' do
          expect do
            response, result = post_graphql(**variables) { query }
            expect(response.status).to eq(200), result.inspect
            count = result.dig('data', 'client', 'eligibleCeOpportunities', 'nodesCount')
            expect(count).to eq(32)
          end.to make_database_queries(count: 15..25)
        end
      end
    end
  end
end
