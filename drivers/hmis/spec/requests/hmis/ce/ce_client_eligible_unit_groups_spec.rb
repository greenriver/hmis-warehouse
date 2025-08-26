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
      { id: client_proxy.id, limit: 25, offset: 0 }
    end

    let!(:candidate_pool) { create :hmis_ce_match_candidate_pool_with_candidates, client_proxies: [client_proxy] }
    let!(:unit_group) do
      create(:hmis_unit_group, project: p1, candidate_pool: candidate_pool)
    end

    it 'returns the correct unit group details' do
      response, result = post_graphql(**variables) { query }
      expect(response.status).to eq(200), result.inspect

      expect(result.dig('data', 'ceClient', 'eligibleUnitGroups', 'nodesCount')).to eq(1)
      unit_group_data = result.dig('data', 'ceClient', 'eligibleUnitGroups', 'nodes').first
      expect(unit_group_data['unitGroupId']).to eq(unit_group.id.to_s)
      expect(unit_group_data['unitGroupName']).to eq(unit_group.name)
      expect(unit_group_data['projectName']).to eq(unit_group.project.name)
    end

    # TODO: test client belonging to one pool that is tied to multiple unit groups
    # TODO: test client belonging to pool that is tied to a stale opportunity
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
