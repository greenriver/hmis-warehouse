###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  let!(:access_control) { create_access_control(hmis_user, ds1) }
  let(:c1) { create(:hmis_hud_client_with_warehouse_client, data_source: ds1) }
  let(:c2) { create(:hmis_hud_client_with_warehouse_client, data_source: ds1) }
  let(:c3_other_ds) { create(:hmis_hud_client_with_warehouse_client) }
  let(:query) do
    <<~GRAPHQL
      query GetMergeCandidates($limit: Int, $offset: Int) {
        mergeCandidates(limit: $limit, offset: $offset) {
          offset
          limit
          nodesCount
          nodes {
            id
            warehouseUrl
            clients {
              id
            }
          }
        }
      }
    GRAPHQL
  end

  before(:each) do
    hmis_login(user)
  end

  def perform_query(**kwargs)
    response, result = post_graphql(**kwargs) { query }
    expect(response.status).to eq(200), result.inspect
    result.dig('data', 'mergeCandidates')
  end

  it 'should return empty if there are no potential merges' do
    result = perform_query
    expect(result['nodes']).to be_empty
  end

  it 'should return candidates for merge' do
    # make 3 clients have the same destination id
    destination_id = c1.warehouse_client_source.destination_id
    c2.warehouse_client_source.update(destination_id: destination_id)
    c3_other_ds.warehouse_client_source.update(destination_id: destination_id) # C3 should not be included

    # confirm setup
    destination_client = c1.destination_client
    expect(destination_client.source_clients.size).to eq(3)
    expect(destination_client.source_clients.pluck(:id)).to contain_exactly(c1.id, c2.id, c3_other_ds.id)

    result = perform_query
    expect(result['nodesCount']).to eq(1)
    expect(result['nodes']).to contain_exactly(include('id' => destination_id.to_s))
    expect(result['nodes'][0]['clients']).to contain_exactly(
      include('id' => c1.id.to_s),
      include('id' => c2.id.to_s),
      # c3_other_ds not be included because it's from a different data source
    )
  end

  it 'should fail if user lacks permission' do
    remove_permissions(access_control, :can_merge_clients)
    expect_gql_error(post_graphql { query })
  end

  it 'should paginate correctly' do
    # Create 8 merge candidates
    8.times.map do
      client1 = create(:hmis_hud_client, data_source: ds1)
      client2 = create(:hmis_hud_client, data_source: ds1)
      wc1 = create(:hmis_warehouse_client, data_source: ds1, source: client1)
      _wc2 = create(:hmis_warehouse_client, data_source: ds1, source: client2, destination_id: wc1.destination_id)
    end

    # first page
    result = perform_query(limit: 5, offset: 0)
    expect(result['nodesCount']).to eq(8)
    expect(result['nodes'].size).to eq(5)

    # second page
    result = perform_query(limit: 5, offset: 5)
    expect(result['nodesCount']).to eq(8)
    expect(result['nodes'].size).to eq(3)
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
