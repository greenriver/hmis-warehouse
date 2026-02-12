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

  describe 'ce_clients query' do
    let(:query) do
      <<~GRAPHQL
        query GetCeClients($limit: Int = 25, $offset: Int = 0, $filters: CeClientFilterOptions = null) {
          ceClients(limit: $limit, offset: $offset, filters: $filters) {
            offset
            limit
            nodesCount
            nodes {
              id
              destinationClientId
              viewableSourceClientIds
              clientName
              clientAttributes
              externalIds {
                id
                identifier
                url
                label
                type
              }
            }
          }
        }
      GRAPHQL
    end

    let(:variables) do
      {}
    end
    let!(:ce_project_config) { create(:hmis_project_ce_config, supports_waitlist_referrals: true, receives_direct_referrals: true, project: p1) }

    context 'when there are ce clients' do
      let!(:client_proxy_no_pools) do
        source_client = create(:hmis_hud_client_with_warehouse_client, data_source: ds1)
        create(:hmis_ce_client_proxy, client: source_client.destination_client)
      end
      let!(:client_proxy_inactive_pools) do
        source_client = create(:hmis_hud_client_with_warehouse_client, data_source: ds1)
        create(:hmis_ce_client_proxy, client: source_client.destination_client)
      end
      let!(:client_proxy_in_pool_1) do
        source_client = create(:hmis_hud_client_with_warehouse_client, data_source: ds1, first_name: 'Jane', last_name: 'Clearwater')
        create(:hmis_ce_client_proxy, client: source_client.destination_client)
      end

      let!(:client_proxy_in_pool_1_and_2) do
        source_client = create(:hmis_hud_client_with_warehouse_client, data_source: ds1, first_name: 'Alex', last_name: 'Ocean')
        create(:hmis_ce_client_proxy, client: source_client.destination_client)
      end

      # Pool 1 is active because it has an active unit group. (And it has an open opportunity)
      let!(:pool_1) { create :hmis_ce_match_candidate_pool_with_candidates, client_proxies: [client_proxy_in_pool_1, client_proxy_in_pool_1_and_2] }
      let!(:pool_1_unit_group) { create :hmis_unit_group, project: p1, candidate_pool: pool_1 }
      let!(:pool_1_unit) { create :hmis_unit, project: p1, unit_group: pool_1_unit_group }
      let!(:pool_1_opportunity) { create :hmis_ce_opportunity, unit: pool_1_unit }

      # Pool 2 is active because it has an active unit group, even though it contains only locked opportunities
      let!(:pool_2) { create :hmis_ce_match_candidate_pool_with_candidates, client_proxies: [client_proxy_in_pool_1_and_2] }
      let!(:p2) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }
      let!(:p2_config) { create(:hmis_project_ce_config, supports_waitlist_referrals: true, project: p2) }
      let!(:pool_2_unit_group) { create :hmis_unit_group, project: p2, candidate_pool: pool_2 }
      let!(:pool_2_unit) { create :hmis_unit, project: p2, unit_group: pool_2_unit_group }
      let!(:pool_2_opportunity) { create :hmis_ce_opportunity, unit: pool_2_unit, status: 'locked' }

      # cruft: Pool 3 is not active because it has no unit group. Candidate membership should be disregarded
      let!(:pool_3) { create :hmis_ce_match_candidate_pool_with_candidates, client_proxies: [client_proxy_inactive_pools, client_proxy_in_pool_1] }

      # cruft: Pool 4 is not active because it is only associated with a deleted unit group. Candidate membership should be disregarded
      let!(:pool_4) { create :hmis_ce_match_candidate_pool_with_candidates, client_proxies: [client_proxy_inactive_pools, client_proxy_in_pool_1] }
      let!(:pool_4_unit_group) { create :hmis_unit_group, project: p1, candidate_pool: pool_4, deleted_at: Time.current - 3.days }

      it 'raises if the user does not have permission' do
        remove_permissions(ds_access_control, :can_administrate_coordinated_entry)
        expect_access_denied post_graphql(**variables) { query }
      end

      it 'excludes clients not belonging to candidate pools' do
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect

        ce_clients = result.dig('data', 'ceClients', 'nodes')

        # Client Proxy that belongs to no pools is excluded
        expect(ce_clients).not_to include(a_hash_including('id' => client_proxy_no_pools.id.to_s))
      end

      it 'excludes clients belonging to inactive candidate pools' do
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect

        ce_clients = result.dig('data', 'ceClients', 'nodes')

        # Client Proxy that belongs to inactive pool is excluded
        expect(ce_clients).not_to include(a_hash_including('id' => client_proxy_inactive_pools.id.to_s))
      end

      it 'includes clients belonging to active candidate pools' do
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect

        ce_clients = result.dig('data', 'ceClients', 'nodes')

        # Client Proxies belonging to pools are included (and not duplicated if belonging to multiple pools)
        expect(ce_clients).to contain_exactly(
          a_hash_including('id' => client_proxy_in_pool_1.id.to_s,
                           'destinationClientId' => client_proxy_in_pool_1.client.id.to_s,
                           'viewableSourceClientIds' => [client_proxy_in_pool_1.client.source_clients.sole.id.to_s],
                           'clientName' => 'Jane Clearwater'),
          a_hash_including('id' => client_proxy_in_pool_1_and_2.id.to_s,
                           'destinationClientId' => client_proxy_in_pool_1_and_2.client.id.to_s,
                           'viewableSourceClientIds' => [client_proxy_in_pool_1_and_2.client.source_clients.sole.id.to_s],
                           'clientName' => 'Alex Ocean'),
        )
      end

      context 'with ce waitlist configuration disabled for p1' do
        before(:each) { ce_project_config.update!(supports_waitlist_referrals: false) }

        it 'excludes clients belonging to inactive pool due to project not being configured for waitlists' do
          expect(pool_1.active?).to be false # confirm setup

          response, result = post_graphql(**variables) { query }
          expect(response.status).to eq(200), result.inspect

          ce_clients = result.dig('data', 'ceClients', 'nodes')

          # client belonging to pool1 is excluded from the list because pool1 is no longer active
          expect(ce_clients).not_to include(a_hash_including('id' => client_proxy_in_pool_1.id.to_s))
          # clinet belonging to pool2 is still included
          expect(ce_clients).to contain_exactly(a_hash_including('id' => client_proxy_in_pool_1_and_2.id.to_s))
        end
      end

      context 'with event snapshots' do
        # events for `client_proxy_in_pool_1`
        let!(:event_add_client1_to_pool_1) { create :hmis_ce_match_candidate_event, candidate_pool: pool_1, client_proxy: client_proxy_in_pool_1, snapshot: { 'current_age' => 19 } }
        let!(:event_remove_client1_from_pool_2) { create :hmis_ce_match_candidate_event, candidate_pool: pool_2, client_proxy: client_proxy_in_pool_1, event_name: 'remove', snapshot: { 'current_age' => 18, 'other_removal_attribute' => 'foo' } }

        # events for `client_proxy_in_pool_1_and_2`
        let!(:event_update_client2_in_pool_1) { create :hmis_ce_match_candidate_event, candidate_pool: pool_1, client_proxy: client_proxy_in_pool_1_and_2, event_name: 'update', snapshot: { 'current_age' => 23, 'pool_1_attr' => '1' } }
        let!(:event_add_client2_to_pool_1) { create :hmis_ce_match_candidate_event, candidate_pool: pool_1, client_proxy: client_proxy_in_pool_1_and_2, snapshot: { 'current_age' => 22 }, created_at: Time.current - 1.month }
        let!(:event_add_client2_to_pool_2) { create :hmis_ce_match_candidate_event, candidate_pool: pool_2, client_proxy: client_proxy_in_pool_1_and_2, snapshot: { 'current_age' => 22, 'pool_2_attr' => '2' }, created_at: Time.current - 1.month }

        it 'resolves clientAttributes based on most recent event snapshots' do
          response, result = post_graphql(**variables) { query }
          expect(response.status).to eq(200), result.inspect

          ce_clients = result.dig('data', 'ceClients', 'nodes')

          # Client Proxies belonging to pools are included (and not duplicated if belonging to multiple pools)
          expect(ce_clients).to contain_exactly(
            a_hash_including('id' => client_proxy_in_pool_1.id.to_s,
                             'clientAttributes' => { 'current_age' => 19 }), # attributes from being added to pool1, does not include irrelevant attribute from being removed from pool2
            a_hash_including('id' => client_proxy_in_pool_1_and_2.id.to_s,
                             'clientAttributes' => { 'current_age' => 23, 'pool_1_attr' => '1', 'pool_2_attr' => '2' }), # latest attributes for both pool1 and pool2 merged
          )
        end
      end

      context 'with mci ID' do
        let!(:mci_cred) { create(:ac_hmis_mci_credential) }
        let(:source_client) { client_proxy_in_pool_1.client.source_clients.sole.as_hmis }
        let!(:mci_id) { create :mci_external_id, source: source_client, remote_credential: mci_cred }

        it 'resolves MCI ID' do
          response, result = post_graphql(**variables) { query }
          expect(response.status).to eq(200), result.inspect

          ce_clients = result.dig('data', 'ceClients', 'nodes')

          expect(ce_clients).to contain_exactly(
            a_hash_including('id' => client_proxy_in_pool_1.id.to_s,
                             'externalIds' => [a_hash_including('type' => 'MCI_ID', 'identifier' => mci_id.value)]),
            a_hash_including('id' => client_proxy_in_pool_1_and_2.id.to_s,
                             'externalIds' => [a_hash_including('type' => 'MCI_ID', 'identifier' => nil)]),
          )
        end
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
