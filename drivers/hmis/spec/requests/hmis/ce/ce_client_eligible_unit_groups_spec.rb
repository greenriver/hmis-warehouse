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
      let!(:unit_groups1) { create_list(:hmis_unit_group, 3, candidate_pool: candidate_pool1) }
      let!(:unit_groups2) { create_list(:hmis_unit_group, 3, candidate_pool: candidate_pool2) }

      it 'returns the correct unit group details' do
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect

        unit_groups_result = result.dig('data', 'ceClient', 'eligibleUnitGroups', 'nodes')
        expect(unit_groups_result.count).to eq(6)
        expect(unit_groups_result.map { |ug| ug['unitGroupId'] }).to match_array(unit_groups1.map { |ug| ug.id.to_s } + unit_groups2.map { |ug| ug.id.to_s })
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
