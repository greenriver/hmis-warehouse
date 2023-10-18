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
    # make 2 clients have the same destination id
    destination_id = c1.warehouse_client_source.destination_id
    c2.warehouse_client_source.update(destination_id: destination_id)
    result = perform_query
    expect(result['nodesCount']).to eq(1)
    expect(result['nodes']).to contain_exactly(include('id' => destination_id.to_s))
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
      wc1 = create(:hmis_warehouse_client, data_source: ds1, source: client1.as_warehouse)
      _wc2 = create(:hmis_warehouse_client, data_source: ds1, source: client2.as_warehouse, destination_id: wc1.destination_id)
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
