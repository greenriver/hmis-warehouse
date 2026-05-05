###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'

RSpec.describe Hmis::GraphqlController, type: :request do
  let!(:data_source) { create :hmis_primary_data_source }
  let!(:user) { create :user }
  let(:hmis_user) { user.related_hmis_user(data_source) }
  let!(:client) { create(:hmis_hud_client, first_name: 'Test', last_name: 'Person', data_source: data_source) }

  before(:each) do
    create_access_control(hmis_user, data_source)
    hmis_login(user)
  end

  let(:query) do
    <<~GRAPHQL
      query ClientOmniSearch($textSearch: String!) {
        clientOmniSearch(textSearch: $textSearch) {
          nodes {
            id
          }
          searchQueryId
        }
      }
    GRAPHQL
  end

  it 'returns matching clients and the search query id' do
    response, result = post_graphql(text_search: 'test person') { query }
    expect(response.status).to eq(200), result.inspect

    nodes = result.dig('data', 'clientOmniSearch', 'nodes')
    search_query_id = result.dig('data', 'clientOmniSearch', 'searchQueryId')

    expect(nodes).to contain_exactly(include('id' => client.id.to_s))

    search_query = Hmis::ClientSearchQuery.find_by(id: search_query_id)
    expect(search_query).to be_present
    expect(search_query.params).to eq({ 'text_search' => 'test person' })
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
