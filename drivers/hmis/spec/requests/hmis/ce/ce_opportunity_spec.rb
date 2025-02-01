require 'rails_helper'
require_relative '../login_and_permissions'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  let!(:ds_access_control) do
    create_access_control(
      hmis_user,
      ds1,
      with_permission: [
        :can_view_clients,
        :can_view_project,
        :can_view_enrollment_details,
      ],
    )
  end

  before(:each) do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    hmis_login(user)
  end

  # Basic setup
  let(:project) { create :hmis_hud_project, data_source: ds1, user: u1 }
  let(:candidate_pool) { create :hmis_ce_match_candidate_pool }
  let(:opportunity) { create :hmis_ce_opportunity, project: project, candidate_pool: candidate_pool }

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
              id
              priorityScore
              client {
                id
                firstName
                lastName
                dateOfBirth: dob
                veteranStatus
              }
            }
            activeReferral {
              id
              status
            }
          }
        }
      GRAPHQL
    end

    let(:variables) do
      {
        id: opportunity.id,
      }
    end

    context 'when querying an opportunity' do
      it 'returns basic opportunity expected results' do
        _, result = post_graphql(**variables) { query }
        opportunity_data = result.dig('data', 'ceOpportunity')

        expect(opportunity_data).to include(
          'id' => opportunity.id.to_s,
          'name' => opportunity.name,
          'status' => opportunity.status,
        )

        candidates = result.dig('data', 'ceOpportunity', 'candidates')

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
        _, result = post_graphql(**variables) { query }
        candidates = result.dig('data', 'ceOpportunity', 'candidates')

        candidate_client_ids = candidates.map { |c| c.dig('client', 'id') }
        expect(candidate_client_ids).not_to include(client_with_active_referral.id.to_s)
      end

      it 'returns the active referral' do
        _, result = post_graphql(**variables) { query }
        active_referral_data = result.dig('data', 'ceOpportunity', 'activeReferral')

        expect(active_referral_data).to include(
          'id' => active_referral.id.to_s,
          'status' => 'in_progress',
        )
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
        _, result = post_graphql(**empty_pool_variables) { query }
        candidates = result.dig('data', 'ceOpportunity', 'candidates')

        expect(candidates).to be_an(Array)
        expect(candidates).to be_empty
      end
    end
  end
end
