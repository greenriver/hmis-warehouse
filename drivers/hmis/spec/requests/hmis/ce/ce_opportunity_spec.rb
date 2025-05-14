# frozen_string_literal: true

require 'rails_helper'
require_relative '../login_and_permissions'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  before(:each) do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    hmis_login(user)
  end

  # Basic setup
  let(:project) { create :hmis_hud_project, data_source: ds1, user: u1 }
  let(:candidate_pool) { create :hmis_ce_match_candidate_pool }
  let(:opportunity) { create :hmis_ce_opportunity, project: project, candidate_pool: candidate_pool }

  let!(:access_control) { create_access_control(hmis_user, project, with_permission: [:can_view_project, :can_view_units, :can_view_prioritized_client_lists, :can_view_referrals]) }

  describe 'ce_opportunity query' do
    let(:query) do
      <<~GRAPHQL
        query GetCeOpportunity($id: ID!) {
          ceOpportunity(id: $id) {
            id
            name
            status
            expiresAt
            candidates {
              nodesCount
              nodes {
                id
                priorityScore
                client {
                  id
                  firstName
                  lastName
                  dateOfBirth: dob
                  veteranStatus
                }
                clientId
              }
            }
            referral {
              id
              status
            }
            eligibilityRequirements {
              id
              name
              ownerType
            }
            candidatesGeneratedAt
          }
        }
      GRAPHQL
    end

    let(:variables) do
      {
        id: opportunity.id,
      }
    end

    context 'when the opportunity has rules' do
      let!(:rule1) { create(:hmis_ce_eligibility_requirement, owner: opportunity) }
      let!(:rule2) { create(:hmis_ce_eligibility_requirement, owner: project) }
      let!(:rule3) { create(:hmis_ce_eligibility_requirement, owner: project.organization, applicability_config: { project_types: [project.project_type] }) }

      let!(:funder) { create(:hmis_hud_funder, project: project, data_source: project.data_source) }
      let!(:rule4) { create(:hmis_ce_eligibility_requirement, owner: project.organization, applicability_config: { project_funders: [funder.funder] }) }

      it 'returns rules with their correct ownerTypes' do
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect

        rules = result.dig('data', 'ceOpportunity', 'eligibilityRequirements')
        expect(rules).to contain_exactly(
          a_hash_including('id' => rule1.id.to_s, 'ownerType' => 'Opportunity'),
          a_hash_including('id' => rule2.id.to_s, 'ownerType' => 'Project'),
          a_hash_including('id' => rule3.id.to_s, 'ownerType' => 'Project Type'),
          a_hash_including('id' => rule4.id.to_s, 'ownerType' => 'Funder'),
        )
      end
    end

    context 'when the opportunity has candidates and an active referral' do
      let!(:ds_access_control) do
        create_access_control(
          hmis_user,
          ds1,
          with_permission: [
            :can_view_clients,
            :can_view_project,
            :can_view_enrollment_details,
            :can_view_referrals,
          ],
        )
      end

      let!(:timestamp) { 2.minutes.ago }
      let(:candidate_pool) { create :hmis_ce_match_candidate_pool, candidates_generated_at: timestamp }

      let!(:client_1) do
        create(:hmis_hud_client, data_source: ds1)
      end
      let!(:client_2) do
        create(:hmis_hud_client, data_source: ds1)
      end
      let!(:client_with_active_referral) do
        create(:hmis_hud_client, data_source: ds1)
      end

      # Create candidates in the pool
      let!(:candidate1) do
        create(
          :hmis_ce_match_candidate,
          candidate_pool: candidate_pool,
          client: client_1,
          priority_score: 80,
        )
      end
      let!(:candidate2) do
        create(
          :hmis_ce_match_candidate,
          candidate_pool: candidate_pool,
          client: client_2,
          priority_score: 100,
        )
      end
      let!(:candidate3) do
        create(
          :hmis_ce_match_candidate,
          candidate_pool: candidate_pool,
          client: client_with_active_referral,
          priority_score: 90,
        )
      end

      # Create an active referral for one client
      let!(:active_referral) do
        create(
          :hmis_ce_referral,
          opportunity: opportunity,
          client: client_with_active_referral,
          status: 'in_progress',
        )
      end

      context 'when querying an opportunity' do
        it 'returns basic opportunity expected results' do
          response, result = post_graphql(**variables) { query }
          expect(response.status).to eq(200), result.inspect

          opportunity_data = result.dig('data', 'ceOpportunity')

          expect(opportunity_data).to include(
            'id' => opportunity.id.to_s,
            'name' => opportunity.name,
            'status' => opportunity.status,
            'candidatesGeneratedAt' => timestamp.iso8601,
          )

          candidates = result.dig('data', 'ceOpportunity', 'candidates', 'nodes')

          expect(candidates).to be_an(Array)
          expect(candidates.length).to eq(2) # Should only include 2 candidates (excluding the one with active referral)

          # Verify candidates are ordered by priority score
          expect(candidates.map { |c| c['priorityScore'] }).to eq([100, 80])

          # Verify first candidate (highest priority)
          expect(candidates[0]).to include(
            'priorityScore' => 100,
            'client' => include(
              'id' => client_2.id.to_s,
            ),
          )

          # Verify second candidate
          expect(candidates[1]).to include(
            'priorityScore' => 80,
            'client' => include(
              'id' => client_1.id.to_s,
            ),
          )
        end

        it 'excludes clients with active referrals' do
          response, result = post_graphql(**variables) { query }
          expect(response.status).to eq(200), result.inspect

          candidates = result.dig('data', 'ceOpportunity', 'candidates', 'nodes')

          candidate_client_ids = candidates.map { |c| c.dig('client', 'id') }
          expect(candidate_client_ids).not_to include(client_with_active_referral.id.to_s)
        end

        it 'returns the active referral' do
          response, result = post_graphql(**variables) { query }
          expect(response.status).to eq(200), result.inspect

          referral_data = result.dig('data', 'ceOpportunity', 'referral')

          expect(referral_data).to include(
            'id' => active_referral.id.to_s,
            'status' => 'in_progress',
          )
        end

        it 'returns no candidates when user lacks permission to see prioritized client lists' do
          remove_permissions(access_control, :can_view_prioritized_client_lists)
          response, result = post_graphql(**variables) { query }
          expect(response.status).to eq(200), result.inspect
          expect(result.dig('data', 'ceOpportunity', 'candidates', 'nodes')).to be_empty
        end
      end
    end

    describe 'when the opportunity has several referrals' do
      # opportunities are single-use, so there should only be one in-progress or accepted referral, but there could be many failed referrals.
      let!(:rejected1) { create(:hmis_ce_referral, opportunity: opportunity, status: 'rejected', created_at: 1.day.ago) }
      let!(:rejected2) { create(:hmis_ce_referral, opportunity: opportunity, status: 'rejected', created_at: 1.day.ago) }
      let!(:rejected3) { create(:hmis_ce_referral, opportunity: opportunity, status: 'rejected', created_at: 1.day.ago) }

      ['initialized', 'in_progress', 'accepted'].each do |status|
        it "returns the #{status} referral" do
          # it should return this referral even if it was created less recently than the rejected referrals (which should not happen)
          referral = create(:hmis_ce_referral, opportunity: opportunity, status: status, created_at: 2.days.ago)
          response, result = post_graphql(**variables) { query }
          expect(response.status).to eq(200), result.inspect
          referral_data = result.dig('data', 'ceOpportunity', 'referral')
          expect(referral_data).to include('id' => referral.id.to_s, 'status' => status)
        end
      end
    end

    context 'when the opportunity has no candidates' do
      let(:empty_pool_opportunity) { create :hmis_ce_opportunity, project: project }

      let(:empty_pool_variables) do
        {
          id: empty_pool_opportunity.id,
        }
      end

      it 'returns an empty candidates array' do
        response, result = post_graphql(**empty_pool_variables) { query }
        expect(response.status).to eq(200), result.inspect

        candidates = result.dig('data', 'ceOpportunity', 'candidates', 'nodes')

        expect(candidates).to be_an(Array)
        expect(candidates).to be_empty
      end
    end

    # TODO(#7573) - fix n+1 and reinstate this test
    context 'when the opportunity has lots of candidates' do
      before do
        200.times do
          client = create(:hmis_hud_client, data_source: ds1)
          create(:hmis_ce_match_candidate, candidate_pool: candidate_pool, client: client, priority_score: rand(80..100))
        end
      end

      xit 'queries the db a reasonable amount' do
        expect do
          response, result = post_graphql(**variables) { query }
          expect(response.status).to eq(200), result.inspect
          expect(result.dig('data', 'ceOpportunity', 'candidates', 'nodesCount')).to eq(200)
        end.to make_database_queries(count: 30..35)
      end
    end

    context 'when the opportunity has some candidates the current user lacks permission to view' do
      let(:candidate_pool_with_anonymous) { create :hmis_ce_match_candidate_pool }
      let(:opportunity) { create :hmis_ce_opportunity, project: project, candidate_pool: candidate_pool_with_anonymous }

      let!(:permissioned_project) { create :hmis_hud_project, data_source: ds1, user: u1 }
      let!(:other_project) { create :hmis_hud_project, data_source: ds1, user: u1 }

      let!(:project_access_control) do
        create_access_control(
          hmis_user,
          permissioned_project,
          with_permission: [
            :can_view_clients,
            :can_view_project,
            :can_view_enrollment_details,
          ],
        )
      end

      let!(:permissioned_client) { create(:hmis_hud_client, data_source: ds1, with_enrollment_at: permissioned_project) }
      let!(:anonymous_client) { create(:hmis_hud_client, data_source: ds1, with_enrollment_at: other_project) }

      let!(:permissioned_candidate) do
        create(
          :hmis_ce_match_candidate,
          candidate_pool: candidate_pool_with_anonymous,
          client: permissioned_client,
          priority_score: 80,
        )
      end
      let!(:anonymous_candidate) do
        create(
          :hmis_ce_match_candidate,
          candidate_pool: candidate_pool_with_anonymous,
          client: anonymous_client,
          priority_score: 100,
        )
      end

      it 'returns some candidates without clients' do
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect

        candidates = result.dig('data', 'ceOpportunity', 'candidates', 'nodes')
        expect(candidates.length).to eq(2)

        candidate1 = candidates.first
        candidate2 = candidates.second
        expect(candidate1.dig('id')).to eq(anonymous_candidate.id.to_s)
        expect(candidate1.dig('client')).to be_nil
        expect(candidate1.dig('clientId')).to eq(anonymous_client.id.to_s)
        expect(candidate2.dig('id')).to eq(permissioned_candidate.id.to_s)
        expect(candidate2.dig('client', 'id')).to eq(permissioned_client.id.to_s)
        expect(candidate2.dig('clientId')).to eq(permissioned_client.id.to_s)
      end
    end

    context 'querying for an opportunity that doesnt exist' do
      let(:variables) do
        {
          id: 9999,
        }
      end

      it 'does not throw, but returns no opportunity' do
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'ceOpportunity')).to be_nil
      end
    end

    describe 'without permission' do
      before do
        remove_permissions(access_control, :can_view_units)
      end

      it 'does not return the opportunity' do
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'ceOpportunity')).to be_nil
      end
    end
  end
end
