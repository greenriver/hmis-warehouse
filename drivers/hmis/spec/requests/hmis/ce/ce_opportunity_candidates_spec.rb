# frozen_string_literal: true

require 'rails_helper'
require_relative '../login_and_permissions'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  let!(:access_control) { create_access_control(hmis_user, ds1) }

  before(:each) do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    hmis_login(user)
  end

  # Create a candidate pool that depends on a custom data element
  let!(:form_definition) { create(:custom_assessment_with_custom_fields, role: :CUSTOM_ASSESSMENT, status: :published, version: 1) }
  # custom_assessment_with_custom_fields factory generates cded "custom_question_1"
  let!(:cded) { create :hmis_custom_data_element_definition, owner_type: 'Hmis::Hud::CustomAssessment', key: 'custom_question_1', form_definition: form_definition }
  let!(:candidate_pool) { create :hmis_ce_match_candidate_pool, priority_expression: 'cde.custom_assessment.custom_question_1' }

  let!(:unit_group) { create(:hmis_unit_group, project: p1, candidate_pool: candidate_pool) }
  let!(:unit) { create(:hmis_unit, project: p1, unit_group: unit_group) }
  let!(:opportunity) { create :hmis_ce_opportunity, candidate_pool: candidate_pool, unit: unit }

  describe 'ceOpportunity candidates query' do
    let(:query) do
      <<~GRAPHQL
        query GetCeOpportunityCandidates(
          $opportunityId: ID!
          $limit: Int = 25
          $offset: Int = 0
          $filters: CeOpportunityCandidatesFilterOptions
        ) {
          ceOpportunity(id: $opportunityId) {
            id
            candidates(limit: $limit, offset: $offset, filters: $filters) {
              offset
              limit
              nodesCount
              nodes {
                id
                priorityScores
                clientName
                clientAttributes
              }
            }
          }
        }
      GRAPHQL
    end

    let(:variables) do
      {
        opportunityId: opportunity.id,
      }
    end

    let!(:client_1) { create(:hmis_hud_client_with_warehouse_client, data_source: ds1) }
    let!(:client_2) { create(:hmis_hud_client_with_warehouse_client, data_source: ds1) }
    let!(:client_3) { create(:hmis_hud_client_with_warehouse_client, data_source: ds1) }

    let!(:candidate1) do
      create(
        :hmis_ce_match_candidate,
        candidate_pool: candidate_pool,
        client: client_1.destination_client,
        priority_score: 50,
      )
    end

    let!(:candidate2) do
      create(
        :hmis_ce_match_candidate,
        candidate_pool: candidate_pool,
        client: client_2.destination_client,
        priority_score: 100,
      )
    end

    let!(:candidate3) do
      create(
        :hmis_ce_match_candidate,
        candidate_pool: candidate_pool,
        client: client_3.destination_client,
        priority_score: 75,
      )
    end

    # One of the candidates has been declined from another opportunity in the same unit group
    let!(:other_unit) { create(:hmis_unit, project: p1, unit_group: unit_group) }
    let!(:other_opportunity) { create(:hmis_ce_opportunity, candidate_pool: candidate_pool, unit: other_unit) }
    let!(:declined_referral) { create(:hmis_ce_referral, data_source: ds1, client: client_1, opportunity: other_opportunity, status: 'rejected', completed_at: 1.day.ago) }

    it 'returns candidates in prioritized order' do
      response, result = post_graphql(**variables) { query }
      expect(response.status).to eq(200), result.inspect

      opportunity_data = result.dig('data', 'ceOpportunity')
      expect(opportunity_data['id']).to eq(opportunity.id.to_s)

      candidates_data = result.dig('data', 'ceOpportunity', 'candidates')
      expect(candidates_data['nodesCount']).to eq(3)
      candidates = candidates_data['nodes']
      expect(candidates.size).to eq(3)

      # Verify all candidates are returned in priority order (highest to lowest)
      # (Even declined candidate, since the filter exclude_declined_clients was not set)
      expect(candidates[0]).to include(
        'id' => candidate2.id.to_s,
        'priorityScores' => [100],
      )

      expect(candidates[1]).to include(
        'id' => candidate3.id.to_s,
        'priorityScores' => [75],
      )

      expect(candidates[2]).to include(
        'id' => candidate1.id.to_s,
        'priorityScores' => [50],
      )
    end

    context 'without can_view_prioritized_client_lists permission' do
      before do
        remove_permissions(access_control, :can_view_prioritized_client_lists)
      end

      it 'returns no candidates' do
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect

        candidates = result.dig('data', 'ceOpportunity', 'candidates', 'nodes')
        expect(candidates).to be_empty
      end
    end

    context 'when the opportunity has no candidates' do
      let!(:unit_group) { create(:hmis_unit_group, project: p1, candidate_pool: nil) }
      let!(:opportunity) { create :hmis_ce_opportunity, candidate_pool: nil, unit: unit }

      it 'returns an empty candidates array' do
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect

        candidates = result.dig('data', 'ceOpportunity', 'candidates', 'nodes')

        expect(candidates).to be_an(Array)
        expect(candidates).to be_empty
      end
    end

    context 'when the opportunity has many candidates' do
      before do
        50.times do
          client = create(:hmis_hud_client_with_warehouse_client, data_source: ds1)
          create(:hmis_ce_match_candidate, candidate_pool: candidate_pool, client: client.destination_client, priority_score: rand(80..100))
        end
      end

      it 'queries the db a reasonable amount' do
        expect do
          response, result = post_graphql(**variables) { query }
          expect(response.status).to eq(200), result.inspect
          expect(result.dig('data', 'ceOpportunity', 'candidates', 'nodesCount')).to eq(53)
        end.to make_database_queries(count: 20..30)
      end
    end

    context 'when the opportunity has some candidates the current user lacks permission to view' do
      let!(:access_control) { create_access_control(hmis_user, p1, with_permission: [:can_view_project, :can_view_units, :can_view_prioritized_client_lists, :can_view_referrals]) }
      let(:candidate_pool_with_anonymous) { create :hmis_ce_match_candidate_pool }
      let!(:unit_group) { create(:hmis_unit_group, project: p1, candidate_pool: candidate_pool_with_anonymous) }
      let(:opportunity) { create :hmis_ce_opportunity, candidate_pool: candidate_pool_with_anonymous, unit: create(:hmis_unit, project: p1, unit_group: unit_group) }

      let!(:permissioned_project) { create :hmis_hud_project, data_source: ds1, user: u1 }
      let!(:other_project) { create :hmis_hud_project, data_source: ds1, user: u1 }

      let!(:project_access_control) do
        create_access_control(
          hmis_user,
          permissioned_project,
          with_permission: [
            :can_view_clients,
            :can_view_client_name,
            :can_view_project,
            :can_view_enrollment_details,
          ],
        )
      end

      let!(:permissioned_client) { create(:hmis_hud_client_with_warehouse_client, data_source: ds1, first_name: 'Permission Yes', last_name: 'Yep') }
      let!(:permissioned_enrollment) { create(:hmis_hud_enrollment, client: permissioned_client, project: permissioned_project, data_source: ds1) }
      let!(:anonymous_client) { create(:hmis_hud_client_with_warehouse_client, data_source: ds1, first_name: 'Permission No', last_name: 'Nope') }
      let!(:anonymous_enrollment) { create(:hmis_hud_enrollment, client: anonymous_client, project: other_project, data_source: ds1) }

      let!(:permissioned_candidate) do
        create(
          :hmis_ce_match_candidate,
          candidate_pool: candidate_pool_with_anonymous,
          client: permissioned_client.destination_client,
          priority_score: 80,
        )
      end
      let!(:anonymous_candidate) do
        create(
          :hmis_ce_match_candidate,
          candidate_pool: candidate_pool_with_anonymous,
          client: anonymous_client.destination_client,
          priority_score: 100,
        )
      end

      it 'returns some candidates without clients' do
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect

        candidates = result.dig('data', 'ceOpportunity', 'candidates', 'nodes')

        expect(candidates).to contain_exactly(
          a_hash_including('id' => permissioned_candidate.id.to_s, 'clientName' => 'Permission Yes Yep'),
          a_hash_including('id' => anonymous_candidate.id.to_s, 'clientName' => "Candidate #{anonymous_candidate.id}"),
        )
      end
    end

    describe 'filtering by exclude_declined_clients' do
      let(:variables) do
        {
          opportunityId: opportunity.id,
          filters: { excludeDeclinedClients: true },
        }
      end

      it 'does not return declined client' do
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect

        candidates = result.dig('data', 'ceOpportunity', 'candidates', 'nodes')
        expect(candidates.size).to eq(2)
        expect(candidates.map { |c| c['id'] }).to contain_exactly(candidate2.id.to_s, candidate3.id.to_s)
      end

      context 'when the client has been reassessed since the decline' do
        let!(:enrollment) { create(:hmis_hud_enrollment, client: client_1, data_source: ds1) }
        let!(:assessment) { create(:hmis_custom_assessment, definition: form_definition, client: client_1, enrollment: enrollment, date_updated: 1.hour.ago) }

        it 'does return declined client who has been reassessed' do
          response, result = post_graphql(**variables) { query }
          expect(response.status).to eq(200), result.inspect

          candidates = result.dig('data', 'ceOpportunity', 'candidates', 'nodes')
          expect(candidates.size).to eq(3)
          expect(candidates.map { |c| c['id'] }).to contain_exactly(candidate1.id.to_s, candidate2.id.to_s, candidate3.id.to_s)
        end
      end

      context 'with many declines' do
        before do
          # create 20 declined clients
          20.times do |i|
            client = create(:hmis_hud_client_with_warehouse_client, data_source: ds1)
            create(:hmis_ce_match_candidate, candidate_pool: candidate_pool, client: client.destination_client, priority_score: 50)

            other_unit = create(:hmis_unit, project: p1, unit_group: unit_group)
            other_opportunity = create(:hmis_ce_opportunity, candidate_pool: candidate_pool, unit: other_unit)
            create(:hmis_ce_referral, data_source: ds1, client: client, opportunity: other_opportunity, status: 'rejected', completed_at: 1.day.ago)

            # re-assess half of them
            if i.even?
              enrollment = create(:hmis_hud_enrollment, client: client, data_source: ds1)
              create(:hmis_custom_assessment, definition: form_definition, client: client, enrollment: enrollment, date_updated: 1.hour.ago)
            end
          end
        end

        it 'does not cause n+1' do
          expect do
            response, result = post_graphql(**variables) { query }
            expect(response.status).to eq(200), result.inspect
            candidates = result.dig('data', 'ceOpportunity', 'candidates', 'nodes')
            expect(candidates.size).to eq(12) # 2 original clients from fixtures + 10 clients who were declined but reassessed
          end.to make_database_queries(count: 30..40)
        end
      end
    end

    describe 'filtering by search_term' do
      let!(:client1) { create(:hmis_hud_client_with_warehouse_client, data_source: ds1, first_name: 'Alice', last_name: 'Anderson') }
      let!(:client2) { create(:hmis_hud_client_with_warehouse_client, data_source: ds1, first_name: 'Bob', last_name: 'Brown') }
      let!(:client3) { create(:hmis_hud_client_with_warehouse_client, data_source: ds1, first_name: 'Charlie', last_name: 'Chaplin') }

      let!(:candidate1) do
        create(
          :hmis_ce_match_candidate,
          candidate_pool: candidate_pool,
          client: client1.destination_client,
          priority_score: 90,
        )
      end

      let!(:candidate2) do
        create(
          :hmis_ce_match_candidate,
          candidate_pool: candidate_pool,
          client: client2.destination_client,
          priority_score: 85,
        )
      end

      let!(:candidate3) do
        create(
          :hmis_ce_match_candidate,
          candidate_pool: candidate_pool,
          client: client3.destination_client,
          priority_score: 80,
        )
      end

      context 'when searching by destination client ID' do
        let(:variables) do
          {
            opportunityId: opportunity.id,
            filters: { searchTerm: client1.destination_client.id.to_s },
          }
        end

        it 'returns the matching candidate' do
          response, result = post_graphql(**variables) { query }
          expect(response.status).to eq(200), result.inspect

          candidates = result.dig('data', 'ceOpportunity', 'candidates', 'nodes')
          expect(candidates.size).to eq(1)
          expect(candidates[0]['id']).to eq(candidate1.id.to_s)
        end
      end

      context 'when searching by source client ID' do
        let(:variables) do
          {
            opportunityId: opportunity.id,
            filters: { searchTerm: client2.id.to_s },
          }
        end

        # todo @martha - will this wokr?
        it 'returns the matching candidate' do
          response, result = post_graphql(**variables) { query }
          expect(response.status).to eq(200), result.inspect

          candidates = result.dig('data', 'ceOpportunity', 'candidates', 'nodes')
          expect(candidates.size).to eq(1)
          expect(candidates[0]['id']).to eq(candidate2.id.to_s)
        end
      end

      context 'when searching by client name' do
        let(:variables) do
          {
            opportunityId: opportunity.id,
            filters: { searchTerm: 'Alice' },
          }
        end

        it 'returns candidates matching the client name' do
          response, result = post_graphql(**variables) { query }
          expect(response.status).to eq(200), result.inspect

          candidates = result.dig('data', 'ceOpportunity', 'candidates', 'nodes')
          expect(candidates.size).to eq(1)
          expect(candidates[0]['id']).to eq(candidate1.id.to_s)
        end
      end

      context 'when search term matches no candidates' do
        let(:variables) do
          {
            opportunityId: opportunity.id,
            filters: { searchTerm: 'Nonexistent' },
          }
        end

        it 'returns empty results' do
          response, result = post_graphql(**variables) { query }
          expect(response.status).to eq(200), result.inspect

          candidates = result.dig('data', 'ceOpportunity', 'candidates', 'nodes')
          expect(candidates).to be_empty
          expect(result.dig('data', 'ceOpportunity', 'candidates', 'nodesCount')).to eq(0)
        end
      end

      context 'when search term is empty string' do
        let(:variables) do
          {
            opportunityId: opportunity.id,
            filters: { searchTerm: '' },
          }
        end

        it 'returns all candidates' do
          response, result = post_graphql(**variables) { query }
          expect(response.status).to eq(200), result.inspect

          candidates = result.dig('data', 'ceOpportunity', 'candidates', 'nodes')
          expect(candidates.size).to eq(3)
        end
      end
    end
  end
end
