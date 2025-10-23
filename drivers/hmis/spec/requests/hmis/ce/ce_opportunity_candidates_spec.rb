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
  let!(:unit) { create(:hmis_unit_in_group, project: p1, unit_group: unit_group) }
  let!(:opportunity) { create :hmis_ce_opportunity, project: p1, data_source: ds1, candidate_pool: candidate_pool, unit: unit }

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

    it 'returns candidates in prioritized order' do
      response, result = post_graphql(**variables) { query }
      expect(response.status).to eq(200), result.inspect

      opportunity_data = result.dig('data', 'ceOpportunity')
      expect(opportunity_data['id']).to eq(opportunity.id.to_s)

      candidates_data = result.dig('data', 'ceOpportunity', 'candidates')
      expect(candidates_data['nodesCount']).to eq(3)
      candidates = candidates_data['nodes']
      expect(candidates.size).to eq(3)

      # Verify candidates are returned in priority order (highest to lowest)
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

    context 'filtering by exclude_recently_declined' do
      let(:variables) do
        {
          opportunityId: opportunity.id,
          filters: { excludeRecentlyDeclined: true },
        }
      end

      let!(:other_unit) { create(:hmis_unit_in_group, project: p1, unit_group: unit_group) }
      let!(:other_opportunity) { create(:hmis_ce_opportunity, project: p1, data_source: ds1, candidate_pool: candidate_pool, unit: other_unit) }
      let!(:declined_referral) { create(:hmis_ce_referral, data_source: ds1, client: client_1, opportunity: other_opportunity, status: 'rejected', completed_at: 1.day.ago) }

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

      # todo @martha - test n+1 queries
    end
  end
end
