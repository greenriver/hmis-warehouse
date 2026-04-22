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
    # Stub CandidatePoolBuilder to prevent it from overwriting the unit groups' pools in after_create callbacks
    allow_any_instance_of(Hmis::Ce::Match::CandidatePoolBuilder).to receive(:call)
    hmis_login(user)
  end

  describe 'ce_clients query' do
    let(:query) do
      <<~GRAPHQL
        query GetCeClients(
          $limit: Int = 25
          $offset: Int = 0
          $filters: CeClientFilterOptions = null
          $clientAttributeKeys: [String!] = null
        ) {
          ceClients(limit: $limit, offset: $offset, filters: $filters) {
            offset
            limit
            nodesCount
            nodes {
              id
              destinationClientId
              viewableSourceClientIds
              clientName
              clientAttributes(keys: $clientAttributeKeys)
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

      context 'when resolving clientAttributes' do
        # Set up a custom data element definition 'my_household_type'
        let!(:custom_assessment_form) { create(:custom_assessment_with_custom_fields, data_source: ds1) }
        let!(:cded_my_household_type) do
          create(:hmis_custom_data_element_definition, owner_type: 'Hmis::Hud::CustomAssessment', key: 'my_household_type', field_type: :string, data_source: ds1, form_definition_identifier: custom_assessment_form.identifier)
        end
        let(:cde_expression_key) { "cde.custom_assessment.#{cded_my_household_type.key}" }
        # Set up a value for this CDE on a client
        let!(:custom_assessment) { create(:hmis_custom_assessment, client: client_proxy_in_pool_1.client.source_clients.sole.as_hmis, definition: custom_assessment_form, data_source: ds1) }
        let!(:custom_data_element) do
          create(:hmis_custom_data_element, value_string: 'Household without children', owner: custom_assessment, data_element_definition: cded_my_household_type, data_source: ds1)
        end

        context 'with no keys provided (backwards compatibility)' do
          it 'returns an empty object' do
            response, result = post_graphql({ client_attribute_keys: nil }) { query }
            expect(response.status).to eq(200), result.inspect

            ce_clients = result.dig('data', 'ceClients', 'nodes')

            expect(ce_clients).to contain_exactly(
              a_hash_including('id' => client_proxy_in_pool_1.id.to_s, 'clientAttributes' => {}),
              a_hash_including('id' => client_proxy_in_pool_1_and_2.id.to_s, 'clientAttributes' => {}),
            )
          end

          context 'when a global CE clients table configuration defines columns' do
            let!(:ce_clients_global_table_config) do
              create(:hmis_table_configuration_ce_clients, data_source: ds1, owner: nil, columns: [{ key: cde_expression_key, type: 'string', label: 'Household Type' }])
            end

            it 'returns fields based on TableConfiguration columns' do
              response, result = post_graphql({ client_attribute_keys: nil }) { query }
              expect(response.status).to eq(200), result.inspect

              ce_clients = result.dig('data', 'ceClients', 'nodes')

              expect(ce_clients).to contain_exactly(
                a_hash_including(
                  'id' => client_proxy_in_pool_1.id.to_s,
                  'clientAttributes' => hash_including(cde_expression_key => 'Household without children'),
                ),
                a_hash_including(
                  'id' => client_proxy_in_pool_1_and_2.id.to_s,
                  'clientAttributes' => hash_including(cde_expression_key => nil),
                ),
              )
            end
          end
        end

        context 'with explicit keys' do
          it 'returns fields for the specified keys' do
            response, result = post_graphql({ client_attribute_keys: [cde_expression_key] }) { query }
            expect(response.status).to eq(200), result.inspect

            ce_clients = result.dig('data', 'ceClients', 'nodes')

            expect(ce_clients).to contain_exactly(
              a_hash_including(
                'id' => client_proxy_in_pool_1.id.to_s,
                'clientAttributes' => { cde_expression_key => 'Household without children' },
              ),
              a_hash_including(
                'id' => client_proxy_in_pool_1_and_2.id.to_s,
                'clientAttributes' => { cde_expression_key => nil },
              ),
            )
          end

          it 'raises if the specified key is not a valid CE expression key' do
            response, result = post_graphql({ client_attribute_keys: ['cde.custom_assessment.not_a_real_cde_key_xyz'] }) { query }
            expect(response.status).to eq(500)
            expect(result.dig('errors', 0, 'message')).to include('Unknown CDE')
          end
        end

        context 'with many custom data element definitions and values' do
          # Setup:
          # - 10 Clients (all belonging to the same candidate pool)
          # - 10 Custom Assessments per client, each with 10 Custom Data Elements (for different definitions)
          # - Query resolves all 10 clients and requests all 10 CDEDs as clientAttributes to resolve
          let!(:cdeds) { create_list(:hmis_custom_data_element_definition, 10, owner_type: 'Hmis::Hud::CustomAssessment', data_source: ds1, form_definition_identifier: custom_assessment_form.identifier) }
          let!(:clients) { create_list(:hmis_hud_client_with_warehouse_client, 10, data_source: ds1) }
          let!(:client_proxies) { clients.map { |client| create(:hmis_ce_client_proxy, client: client.destination_client) } }
          let!(:custom_assessments) do
            clients.each do |client|
              10.times do |i|
                custom_assessment = create(:hmis_custom_assessment, client: client, definition: custom_assessment_form, data_source: ds1)
                cdeds.each do |cded|
                  create(:hmis_custom_data_element, value_string: "Value #{i}", owner: custom_assessment, data_element_definition: cded, data_source: ds1)
                end
              end
            end
          end
          # add clients to pool_1 so they show up in the results
          let!(:pool_1) { create :hmis_ce_match_candidate_pool_with_candidates, client_proxies: client_proxies }
          let(:keys) { cdeds.map(&:key).map { |key| "cde.custom_assessment.#{key}" } }

          it 'returns all custom data elements in a reasonable number of queries' do
            expect(clients.flat_map(&:custom_assessments).flat_map(&:custom_data_elements).count).to eq(100) # validate setup

            expect do
              response, result = post_graphql({ client_attribute_keys: keys }) { query }
              expect(response.status).to eq(200), result.inspect

              # ensure large amount of CDE values were returned
              ce_clients = result.dig('data', 'ceClients', 'nodes')
              expect(ce_clients.count).to be > 10
              expect(ce_clients.map { |client| client['clientAttributes'] }.map(&:values).flatten.compact_blank.count).to eq(100)
            end.to make_database_queries(count: 25..40)
          end
        end
      end

      context 'with live CDE dynamic filters' do
        let!(:form_for_cde_filter) do
          create(
            :hmis_form_definition,
            role: :CUSTOM_ASSESSMENT,
            identifier: "ceLiveFilterFd#{SecureRandom.hex(4)}",
            data_source: ds1,
          )
        end
        let!(:cded_filter_score) do
          create(
            :hmis_custom_data_element_definition,
            owner_type: 'Hmis::Hud::CustomAssessment',
            key: 'filter_score',
            field_type: :integer,
            data_source: ds1,
            user: u1,
            form_definition_identifier: form_for_cde_filter.identifier,
          )
        end

        let!(:jane_hmis_client) { Hmis::Hud::Client.find(client_proxy_in_pool_1.client.source_clients.sole.id) }
        let!(:jane_enrollment) { create(:hmis_hud_enrollment, data_source: ds1, client: jane_hmis_client) }
        let!(:jane_assessment) do
          create(
            :hmis_custom_assessment,
            client: jane_hmis_client,
            enrollment: jane_enrollment,
            definition: form_for_cde_filter,
            data_source: ds1,
          )
        end
        let!(:jane_cde_value) do
          create(
            :hmis_custom_data_element,
            owner: jane_assessment,
            data_element_definition: cded_filter_score,
            value_integer: 99,
            data_source: ds1,
            user: u1,
          )
        end

        it 'filters ce clients by live CDE value on latest assessment' do
          filter_variables = {
            filters: {
              dynamicFilters: [
                { key: 'cde.custom_assessment.filter_score', values: ['99'] },
              ],
            },
          }
          response, result = post_graphql(**filter_variables) { query }
          expect(response.status).to eq(200), result.inspect

          ce_clients = result.dig('data', 'ceClients', 'nodes')
          expect(ce_clients).to contain_exactly(
            a_hash_including('id' => client_proxy_in_pool_1.id.to_s),
          )
        end

        it 'returns no clients when live CDE value does not match' do
          filter_variables = {
            filters: {
              dynamicFilters: [
                { key: 'cde.custom_assessment.filter_score', values: ['100'] },
              ],
            },
          }
          response, result = post_graphql(**filter_variables) { query }
          expect(response.status).to eq(200), result.inspect

          ce_clients = result.dig('data', 'ceClients', 'nodes')
          expect(ce_clients).to eq([])
        end

        it 'rejects non-cde dynamic filter keys' do
          filter_variables = {
            filters: {
              dynamicFilters: [
                { key: 'current_age', values: ['20'] },
              ],
            },
          }
          expect_gql_error post_graphql(**filter_variables) { query }, message: /Unknown CDE in field/
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
