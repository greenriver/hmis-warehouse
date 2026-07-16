###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require_relative '../../../support/ce_spec_helper'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  let!(:ds_access_control) do
    create_access_control(
      hmis_user, ds1,
      with_permission: [
        :can_view_project,
        :can_administrate_coordinated_entry,
      ]
    )
  end

  before(:each) do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    allow_any_instance_of(Hmis::Ce::Match::CandidatePoolBuilder).to receive(:call)
    hmis_login(user)
  end

  describe 'ce_candidate_pool_summary query' do
    let(:query) do
      <<~GRAPHQL
        query GetCeCandidatePoolSummary($projectGroupId: ID) {
          ceCandidatePoolSummary(projectGroupId: $projectGroupId) {
            totalCount
            neverGeneratedCount
            pendingRefreshCount
          }
        }
      GRAPHQL
    end

    let!(:ce_project_config) { create(:hmis_project_ce_config, supports_waitlist_referrals: true, project: p1) }

    # Active pool with completed generation and clean marker
    let!(:pool_generated) { create(:hmis_ce_match_candidate_pool, candidates_generated_at: 1.day.ago) }
    let!(:pool_generated_unit_group) { create(:hmis_unit_group, project: p1, candidate_pool: pool_generated) }
    let!(:pool_generated_marker) { create(:hmis_ce_change_marker, trackable: pool_generated, current_version: 1, processed_version: 1) }

    # Active pool that has never completed generation (dirty marker)
    let!(:pool_never_generated) { create(:hmis_ce_match_candidate_pool, candidates_generated_at: nil) }
    let!(:pool_never_generated_unit_group) { create(:hmis_unit_group, project: p1, candidate_pool: pool_never_generated) }
    let!(:pool_never_generated_marker) { create(:hmis_ce_change_marker, trackable: pool_never_generated, current_version: 1, processed_version: 0) }

    # Active pool with prior generation but dirty marker (nightly reprocessing or pool change)
    let!(:pool_pending_refresh) { create(:hmis_ce_match_candidate_pool, candidates_generated_at: 2.days.ago) }
    let!(:pool_pending_refresh_unit_group) { create(:hmis_unit_group, project: p1, candidate_pool: pool_pending_refresh) }
    let!(:pool_pending_refresh_marker) { create(:hmis_ce_change_marker, trackable: pool_pending_refresh, current_version: 2, processed_version: 1) }

    # Inactive pool (deleted unit group) — excluded
    let!(:pool_inactive) { create(:hmis_ce_match_candidate_pool, candidates_generated_at: 1.day.ago) }
    let!(:pool_inactive_unit_group) { create(:hmis_unit_group, project: p1, candidate_pool: pool_inactive, deleted_at: 3.days.ago) }

    # Pool in another data source — excluded
    let!(:other_ds) { create(:hmis_data_source) }
    let!(:other_project) { create(:hmis_hud_project, data_source: other_ds, organization: create(:hmis_hud_organization, data_source: other_ds)) }
    let!(:other_project_config) { create(:hmis_project_ce_config, supports_waitlist_referrals: true, project: other_project) }
    let!(:pool_other_ds) { create(:hmis_ce_match_candidate_pool, candidates_generated_at: nil) }
    let!(:pool_other_ds_unit_group) { create(:hmis_unit_group, project: other_project, candidate_pool: pool_other_ds) }

    # Pool outside project group when scoped
    let!(:p2) { create(:hmis_hud_project, data_source: ds1, organization: o1, user: u1) }
    let!(:p2_config) { create(:hmis_project_ce_config, supports_waitlist_referrals: true, project: p2) }
    let!(:pool_outside_group) { create(:hmis_ce_match_candidate_pool, candidates_generated_at: nil) }
    let!(:pool_outside_group_unit_group) { create(:hmis_unit_group, project: p2, candidate_pool: pool_outside_group) }
    let!(:pool_outside_group_marker) { create(:hmis_ce_change_marker, trackable: pool_outside_group, current_version: 1, processed_version: 0) }

    let!(:project_group) { create(:hmis_project_group, data_source: ds1, with_projects: [p1]) }

    it 'raises if the user does not have permission' do
      remove_permissions(ds_access_control, :can_administrate_coordinated_entry)
      expect_gql_error(post_graphql({}) { query })
    end

    it 'returns counts for active pools in the current data source' do
      _response, result = post_graphql({}) { query }
      summary = result.dig('data', 'ceCandidatePoolSummary')

      aggregate_failures do
        # generated, never_generated, pending_refresh, outside_group (4 active pools in ds1)
        expect(summary['totalCount']).to eq(4)
        expect(summary['neverGeneratedCount']).to eq(2)
        expect(summary['pendingRefreshCount']).to eq(3)
      end
    end

    it 'scopes counts to the specified project group' do
      _response, result = post_graphql(projectGroupId: project_group.id) { query }
      summary = result.dig('data', 'ceCandidatePoolSummary')

      aggregate_failures do
        expect(summary['totalCount']).to eq(3)
        expect(summary['neverGeneratedCount']).to eq(1)
        expect(summary['pendingRefreshCount']).to eq(2)
      end
    end
  end
end
