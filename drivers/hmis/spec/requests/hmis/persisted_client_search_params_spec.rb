###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'

##
# Request spec for the persistedClientSearchParams GraphQL endpoint.
# Covers:
# - Basic test confirming the underlying ClientSearchQuery is returned with the correct fields
# - Basic confirmation that user can't access queries created by other users
RSpec.describe Hmis::GraphqlController, type: :request do
  let!(:data_source) { create :hmis_primary_data_source }
  let!(:user) { create :user }
  let(:hmis_user) { user.related_hmis_user(data_source) }

  before(:each) do
    hmis_login(user)
  end

  let(:query) do
    <<~GRAPHQL
      query GetPersistedClientSearchParams($id: ID!) {
        persistedClientSearchParams(id: $id) {
          id
          textSearch
          personalId
          firstName
          lastName
          ssnSerial
          dob
        }
      }
    GRAPHQL
  end

  [
    { 'text_search' => 'my test search' },
    { 'personal_id' => '1234567890' },
    { 'first_name' => 'John' },
    { 'last_name' => 'Doe' },
    { 'ssn_serial' => '1234' },
    { 'dob' => '1990-01-01' },
  ].each do |params|
    context "when the search query exists with #{params.keys.join(', ')}" do
      let!(:search_query) { create :hmis_client_search_query, created_by: hmis_user, params: params }

      it 'returns the search query' do
        response, result = post_graphql(id: search_query.id) { query }
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'persistedClientSearchParams', 'id')).to eq(search_query.id)
        params.each do |key, value|
          expect(result.dig('data', 'persistedClientSearchParams', key.camelize(:lower))).to eq(value)
        end
      end
    end
  end

  context 'when the search query was created by a different user' do
    let!(:other_user) { create :hmis_user, data_source: data_source }
    let!(:search_query) { create :hmis_client_search_query, created_by: other_user }

    it 'returns nil' do
      response, result = post_graphql(id: search_query.id) { query }
      expect(response.status).to eq(200), result.inspect
      expect(result.dig('data', 'persistedSearchParams')).to be_nil
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
