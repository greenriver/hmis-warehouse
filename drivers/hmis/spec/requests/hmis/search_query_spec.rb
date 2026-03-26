###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  let!(:data_source) { create :hmis_primary_data_source }
  let!(:user) { create :user }
  let(:hmis_user) { user.related_hmis_user(data_source) }

  before(:each) do
    hmis_login(user)
  end

  let(:query) do
    <<~GRAPHQL
      query SearchQuery($id: ID!) {
        searchQuery(id: $id) {
          id
          textSearch
        }
      }
    GRAPHQL
  end

  context 'when the search query exists' do
    let!(:search_query) { create :hmis_client_search_query, created_by: hmis_user, params: { 'text_search' => 'my test search' } }

    it 'returns the search query' do
      response, result = post_graphql(id: search_query.id) { query }
      expect(response.status).to eq(200), result.inspect
      expect(result.dig('data', 'searchQuery', 'id')).to eq(search_query.id)
      expect(result.dig('data', 'searchQuery', 'textSearch')).to eq('my test search')
    end
  end

  context 'when the search query was created by a different user' do
    let!(:other_user) { create :hmis_user, data_source: data_source }
    let!(:search_query) { create :hmis_client_search_query, created_by: other_user }

    it 'returns nil' do
      response, result = post_graphql(id: search_query.id) { query }
      expect(response.status).to eq(200), result.inspect
      expect(result.dig('data', 'searchQuery')).to be_nil
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
