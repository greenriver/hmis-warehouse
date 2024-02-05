###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  let!(:access_control) { create_access_control(hmis_user, ds1) }

  before(:each) do
    hmis_login(user)
  end

  describe 'client merge' do
    let(:c1) { create(:hmis_hud_client_complete, data_source: ds1) }
    let(:c2) { create(:hmis_hud_client_complete, data_source: ds1) }
    let(:mutation) do
      <<~GRAPHQL
        mutation MergeClients($input: MergeClientsInput!) {
          mergeClients(input: $input) {
            client {
              id
            }
            #{error_fields}
          }
        }
      GRAPHQL
    end

    it 'should perform merge' do
      client_ids = [c1.id, c2.id]
      response, result = post_graphql(input: { client_ids: client_ids }) { mutation }
      expect(response.status).to eq(200), result.inspect
      remaining_clients = Hmis::Hud::Client.where(id: client_ids)
      expect(remaining_clients.size).to eq(1)
      expect(result.dig('data', 'mergeClients', 'client', 'id')).to eq(remaining_clients.first.id.to_s)
    end

    it 'should fail if user lacks permission' do
      remove_permissions(access_control, :can_view_clients)
      expect_gql_error post_graphql(input: { client_ids: [c1.id, c2.id] }) { mutation }
    end

    it 'should fail if any clients are not viewable' do
      # try to merge with client in another data source
      c3 = create(:hmis_hud_client_complete)
      expect_gql_error post_graphql(input: { client_ids: [c1.id, c3.id] }) { mutation }
    end
  end

  describe 'bulk client merge' do
    let(:c1) { create(:hmis_hud_client_complete, data_source: ds1) }
    let(:c2) { create(:hmis_hud_client_complete, data_source: ds1) }
    let(:c3) { create(:hmis_hud_client_complete, data_source: ds1) }
    let(:c4) { create(:hmis_hud_client_complete, data_source: ds1) }
    let(:c5) { create(:hmis_hud_client_complete, data_source: ds1) }

    let(:mutation) do
      <<~GRAPHQL
        mutation BulkMergeClients($input: BulkMergeClientsInput!) {
          bulkMergeClients(input: $input) {
            success
            #{error_fields}
          }
        }
      GRAPHQL
    end

    it 'should perform merges' do
      client_ids1 = [c1.id, c2.id]
      client_ids2 = [c3.id, c4.id, c5.id]
      response, result = post_graphql(input: { input: [{ client_ids: client_ids1 }, { client_ids: client_ids2 }] }) { mutation }
      expect(response.status).to eq(200), result.inspect
      expect(Hmis::Hud::Client.where(id: client_ids1).size).to eq(1)
      expect(Hmis::Hud::Client.where(id: client_ids2).size).to eq(1)

      # hijack this test, ensure deleted id search works
      [
        client_ids1,
        client_ids2,
      ].each do |ids|
        ids.each do |id|
          results = Hmis::Hud::Client.searchable_to(hmis_user).matching_search_term(id.to_s)
          expect(results.map(&:id)).to contain_exactly(ids.first)
        end
      end
    end

    it 'should fail if user lacks permission' do
      remove_permissions(access_control, :can_view_clients)
      expect_gql_error post_graphql(input: { input: [{ client_ids: [c1.id, c2.id] }] }) { mutation }
    end

    it 'should fail if any clients are not viewable' do
      # try to merge with client in another data source
      c6 = create(:hmis_hud_client_complete)
      expect_gql_error post_graphql(input: { input: [{ client_ids: [c1.id, c6.id] }] }) { mutation }
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
