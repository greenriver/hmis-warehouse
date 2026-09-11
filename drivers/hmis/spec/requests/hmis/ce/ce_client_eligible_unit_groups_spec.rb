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
        :can_view_clients,
        :can_view_client_name,
        :can_view_project,
        :can_administrate_coordinated_entry,
      ]
    )
  end
  before(:each) do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    # Stub CandidatePoolBuilder so after_create on unit groups does not overwrite the assigned pool
    allow_any_instance_of(Hmis::Ce::Match::CandidatePoolBuilder).to receive(:call)
    hmis_login(user)
  end

  describe 'ce_client#eligible_unit_groups query' do
    let(:query) do
      <<~GRAPHQL
        query GetCeClientEligibleUnitGroups($id: ID!, $limit: Int = 25, $offset: Int = 0) {
          ceClient(id: $id) {
            id
            eligibleUnitGroups(limit: $limit, offset: $offset) {
              nodesCount
              nodes {
                id
                unitGroupId
                unitGroupName
                projectName
                projectId
                projectType
                organizationName
                candidateCreatedAt
                candidateUpdatedAt
                unitsAcceptingReferrals
              }
            }
          }
        }
      GRAPHQL
    end

    let!(:client_proxy) do
      source_client = create(:hmis_hud_client_with_warehouse_client, data_source: ds1, first_name: 'John', last_name: 'Doe')
      create(:hmis_ce_client_proxy, client: source_client.destination_client)
    end

    let(:variables) do
      { id: client_proxy.id }
    end
    let!(:ce_project_config) { create(:hmis_project_ce_config, supports_waitlist_referrals: true, project: p1) }

    context 'when client belongs to one candidate pool tied to one unit group' do
      let!(:candidate_pool) { create :hmis_ce_match_candidate_pool_with_candidates, client_proxies: [client_proxy] }
      let!(:unit_group) { create(:hmis_unit_group, project: p1, candidate_pool: candidate_pool) }

      it 'returns the correct unit group details' do
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect

        unit_groups_result = result.dig('data', 'ceClient', 'eligibleUnitGroups', 'nodes')
        expect(unit_groups_result.count).to eq(1)
        expect(unit_groups_result).to contain_exactly(
          a_hash_including(
            'unitGroupId' => unit_group.id.to_s,
            'unitGroupName' => unit_group.name,
            'projectName' => unit_group.project.name,
          ),
        )
      end

      it 'raises if the user does not have permission' do
        remove_permissions(ds_access_control, :can_administrate_coordinated_entry)
        expect_access_denied post_graphql(**variables) { query }
      end
    end

    context 'when client belongs to one candidate pool tied to multiple unit group' do
      let!(:candidate_pool) { create :hmis_ce_match_candidate_pool_with_candidates, client_proxies: [client_proxy] }
      let!(:unit_groups) { create_list(:hmis_unit_group, 5, project: p1, candidate_pool: candidate_pool) }

      it 'returns the correct unit group details' do
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect

        unit_groups_result = result.dig('data', 'ceClient', 'eligibleUnitGroups', 'nodes')
        expect(unit_groups_result.count).to eq(5)
        expect(unit_groups_result.map { |ug| ug['unitGroupId'] }).to match_array(unit_groups.map { |ug| ug.id.to_s })
      end
    end

    context 'when client belongs to multiple candidate pools, each tied to multiple unit groups in different projects' do
      let!(:candidate_pool1) { create :hmis_ce_match_candidate_pool_with_candidates, client_proxies: [client_proxy] }
      let!(:candidate_pool2) { create :hmis_ce_match_candidate_pool_with_candidates, client_proxies: [client_proxy] }
      let!(:p2) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }
      let!(:p2_config) { create(:hmis_project_ce_config, supports_waitlist_referrals: true, project: p2) }
      let!(:unit_groups1) { create_list(:hmis_unit_group, 3, project: p1, candidate_pool: candidate_pool1) }
      let!(:unit_groups2) { create_list(:hmis_unit_group, 3, project: p2, candidate_pool: candidate_pool2) }

      it 'returns the correct unit group details' do
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect

        unit_groups_result = result.dig('data', 'ceClient', 'eligibleUnitGroups', 'nodes')
        expect(unit_groups_result.count).to eq(6)
        expect(unit_groups_result.map { |ug| ug['unitGroupId'] }).to match_array(unit_groups1.map { |ug| ug.id.to_s } + unit_groups2.map { |ug| ug.id.to_s })
      end
    end

    context 'when the client has candidate rows in inactive pools' do
      let!(:active_pool) { create :hmis_ce_match_candidate_pool_with_candidates, client_proxies: [client_proxy] }
      let!(:active_unit_group) { create(:hmis_unit_group, project: p1, candidate_pool: active_pool) }

      # Waitlist inactive because the project is closed
      let!(:closed_project) { create(:hmis_hud_project, data_source: ds1, organization: o1, user: u1, operating_end_date: 1.week.ago) }
      let!(:closed_project_config) { create(:hmis_project_ce_config, supports_waitlist_referrals: true, project: closed_project) }
      let!(:closed_pool) { create :hmis_ce_match_candidate_pool_with_candidates, client_proxies: [client_proxy] }
      let!(:closed_unit_group) { create(:hmis_unit_group, project: closed_project, candidate_pool: closed_pool) }

      # Waitlist inactive because the unit group has no waitlist referral workflow
      let!(:p_no_workflow) { create(:hmis_hud_project, data_source: ds1, organization: o1, user: u1) }
      let!(:p_no_workflow_config) { create(:hmis_project_ce_config, supports_waitlist_referrals: true, project: p_no_workflow) }
      let!(:no_workflow_pool) { create :hmis_ce_match_candidate_pool_with_candidates, client_proxies: [client_proxy] }
      let!(:no_workflow_unit_group) { create(:hmis_unit_group, project: p_no_workflow, candidate_pool: no_workflow_pool, workflow_template: nil) }

      # Waitlist inactive because the project no longer supports waitlist referrals
      let!(:p_waitlists_off) { create(:hmis_hud_project, data_source: ds1, organization: o1, user: u1) }
      let!(:p_waitlists_off_config) { create(:hmis_project_ce_config, supports_waitlist_referrals: false, receives_direct_referrals: true, project: p_waitlists_off) }
      let!(:waitlists_off_pool) { create :hmis_ce_match_candidate_pool_with_candidates, client_proxies: [client_proxy] }
      let!(:waitlists_off_unit_group) { create(:hmis_unit_group, project: p_waitlists_off, candidate_pool: waitlists_off_pool) }

      it 'omits unit groups from inactive pools' do
        expect(active_pool.active?).to be true
        expect(closed_pool.active?).to be false
        expect(no_workflow_pool.active?).to be false
        expect(waitlists_off_pool.active?).to be false

        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect

        unit_groups_result = result.dig('data', 'ceClient', 'eligibleUnitGroups', 'nodes')
        expect(unit_groups_result.map { |ug| ug['unitGroupId'] }).to contain_exactly(active_unit_group.id.to_s)
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
