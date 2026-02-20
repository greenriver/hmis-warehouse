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
  let!(:project) { create :hmis_hud_project, data_source: ds1, user: u1, project_type: 1 }
  let!(:unit_group) { create(:hmis_unit_group, project: project, workflow_template: create(:hmis_workflow_definition_template, data_source: ds1)) }
  let!(:unit) { create(:hmis_unit, project: project, unit_group: unit_group) }
  let!(:opportunity) { create :hmis_ce_opportunity, unit: unit }

  let!(:access_control) { create_access_control(hmis_user, project, with_permission: [:can_view_project, :can_view_units, :can_view_prioritized_client_lists, :can_view_referrals]) }

  describe 'GetUnit query' do
    let(:query) do
      <<~GRAPHQL
        query GetUnit($id: ID!) {
          unit(id: $id) {
            id
            name
            unitGroup { id }
            eligibilityRequirements {
              ...CeMatchRuleFields
            }
            prioritySchemes {
              ...CeMatchRuleFields
            }
            latestOpportunity {
              id
              name
              status
              stale
              referral {
                id
                status
              }
              candidatesGeneratedAt
              candidates(
                limit: 1
                offset: 0
              ) {
                nodes {
                  id
                  priorityScores
                  clientName
                  clientAttributes
                }
              }
            }
            # later: opportunities (history of all opportunities (and referrals) for this unit)
          }
        }

        fragment CeMatchRuleFields on CeMatchRule {
          id
          name
          ownerType
          expression
          projectTypes
          funders
        }
      GRAPHQL
    end

    let(:variables) do
      {
        id: unit.id,
      }
    end

    context 'when the unit has rules' do
      let!(:rule1) { create(:hmis_ce_eligibility_requirement, owner: unit.unit_group) }
      let!(:rule2) { create(:hmis_ce_eligibility_requirement, owner: project) }
      let!(:rule3) { create(:hmis_ce_eligibility_requirement, owner: project.organization, applicability_config: { project_types: [project.project_type] }) }

      let!(:funder) { create(:hmis_hud_funder, project: project, data_source: project.data_source) }
      let!(:rule4) { create(:hmis_ce_eligibility_requirement, owner: project.organization, applicability_config: { project_funders: [funder.funder] }) }
      before do
        # Ensure the unit group gets associated with a candidate pool
        Hmis::Ce::Match::CandidatePoolBuilder.call
      end

      it 'returns rules with their correct ownerTypes' do
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect

        rules = result.dig('data', 'unit', 'eligibilityRequirements')
        expect(rules).to contain_exactly(
          a_hash_including('id' => rule1.id.to_s, 'ownerType' => 'UNIT_GROUP'),
          a_hash_including('id' => rule2.id.to_s, 'ownerType' => 'PROJECT'),
          a_hash_including('id' => rule3.id.to_s, 'ownerType' => 'ORGANIZATION', 'projectTypes' => ['ES_NBN']),
          a_hash_including('id' => rule4.id.to_s, 'ownerType' => 'ORGANIZATION', 'funders' => ['HUD_HUD_VASH']),
        )
      end

      it 'returns most-specific priority schemes ordered by rank, then id' do
        # Build assignment rules with mixed owners and ranks
        create(:hmis_ce_priority_scheme, owner: project.organization, expression: 'org_expr', priority_rank: 2)
        create(:hmis_ce_priority_scheme, owner: project, expression: 'proj_low', priority_rank: 2)
        create(:hmis_ce_priority_scheme, owner: project, expression: 'proj_high', priority_rank: 1)
        create(:hmis_ce_priority_scheme, owner: project.data_source, expression: 'ds_expr', priority_rank: 1)

        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect

        prios = result.dig('data', 'unit', 'prioritySchemes')
        # Should only include project-level rules, ordered by priority_rank then id
        expect(prios.map { |r| r['expression'] }).to eq(['proj_high', 'proj_low'])
      end
    end

    describe 'when the opportunity has several referrals' do
      # opportunities are single-use, so there should only be one in-progress or accepted referral, but there could be many failed referrals.
      let!(:rejected1) { create(:hmis_ce_referral, opportunity: opportunity, data_source: ds1, status: 'rejected', created_at: 1.day.ago) }
      let!(:rejected2) { create(:hmis_ce_referral, opportunity: opportunity, data_source: ds1, status: 'rejected', created_at: 1.day.ago) }
      let!(:rejected3) { create(:hmis_ce_referral, opportunity: opportunity, data_source: ds1, status: 'rejected', created_at: 1.day.ago) }

      ['initialized', 'in_progress', 'accepted'].each do |status|
        it "returns the #{status} referral" do
          # it should return this referral even if it was created less recently than the rejected referrals (which should not happen)
          referral = create(:hmis_ce_referral, opportunity: opportunity, data_source: ds1, status: status, created_at: 2.days.ago)
          response, result = post_graphql(**variables) { query }
          expect(response.status).to eq(200), result.inspect
          referral_data = result.dig('data', 'unit', 'latestOpportunity', 'referral')
          expect(referral_data).to include('id' => referral.id.to_s, 'status' => status)
        end
      end
    end

    context 'querying for a unit that doesnt exist' do
      let(:variables) do
        {
          id: 9999,
        }
      end

      it 'does not throw, but returns no unit' do
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'unit')).to be_nil
      end
    end

    describe 'without permission' do
      before do
        remove_permissions(access_control, :can_view_units)
      end

      it 'does not return the unit' do
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'unit')).to be_nil
      end
    end
  end
end
