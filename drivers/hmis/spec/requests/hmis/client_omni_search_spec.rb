###
# Copyright Green River Data Group, Inc.
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

  def omni_search_ids(text)
    response, result = post_graphql(text_search: text) { query }
    expect(response.status).to eq(200), result.inspect
    result.dig('data', 'clientOmniSearch', 'nodes').map { |node| node['id'].to_i }
  end

  context 'with access to the whole data source' do
    let!(:client) { create(:hmis_hud_client, first_name: 'Test', last_name: 'Person', data_source: data_source) }

    before(:each) do
      create_access_control(hmis_user, data_source)
      hmis_login(user)
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

  context 'with access to one project' do
    let!(:other_data_source) { create :hmis_data_source }
    let!(:p1) { create :hmis_hud_project, data_source: data_source }
    let!(:p2) { create :hmis_hud_project, data_source: data_source }
    let!(:client_at_p1) { create(:hmis_hud_client, first_name: 'Test', last_name: 'Person', data_source: data_source, with_enrollment_at: p1) }
    let!(:client_at_p2) { create(:hmis_hud_client, first_name: 'Test', last_name: 'Person', data_source: data_source, with_enrollment_at: p2) }
    let!(:client_in_other_data_source) { create(:hmis_hud_client, first_name: 'Test', last_name: 'Person', data_source: other_data_source) }

    before(:each) do
      create_access_control(hmis_user, p1, without_permission: :can_view_restricted_clients)
      hmis_login(user)
    end

    it 'returns only matching clients the user can search' do
      expect(omni_search_ids('test person')).to contain_exactly(client_at_p1.id)
    end

    it 'returns nothing when nothing matches' do
      expect(omni_search_ids('zzqx wvut')).to be_empty
    end

    it 'omits a matching restricted client' do
      client_at_p1.mark_as_restricted!(user: hmis_user)
      expect(omni_search_ids('test person')).to be_empty
    end

    it 'finds a client by scan card only within the data source' do
      own_card = create(:hmis_scan_card_code, client: client_at_p1)
      other_card = create(:hmis_scan_card_code, client: client_in_other_data_source)
      expect(omni_search_ids(own_card.value)).to contain_exactly(client_at_p1.id)
      expect(omni_search_ids(other_card.value)).to be_empty
    end

    it 'finds a client by id only if the user can search them' do
      expect(omni_search_ids(client_at_p1.id.to_s)).to contain_exactly(client_at_p1.id)
      expect(omni_search_ids(client_at_p2.id.to_s)).to be_empty
      expect(omni_search_ids(client_in_other_data_source.id.to_s)).to be_empty
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
