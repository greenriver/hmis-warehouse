###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'Manage Scan Card Mutations', type: :request do
  include_context 'hmis base setup'

  let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_view_clients]) }
  before(:each) do
    hmis_login(user)
  end

  describe 'scan code query' do
    let(:query) do
      <<~GRAPHQL
        query GetClientScanCardCodes($id: ID!) {
          client(id: $id) {
            id
            scanCardCodes(limit: 20, offset: 0) {
              offset
              limit
              nodesCount
              nodes {
                id
                code
              }
            }
          }
        }
      GRAPHQL
    end
    let!(:client) { create(:hmis_hud_client, data_source: ds1) }
    let!(:code1) { create(:hmis_scan_card_code, client: client) }
    let!(:code2) { create(:hmis_scan_card_code, client: client, deleted_at: Time.current) }

    it 'resolves codes' do
      response, result = post_graphql(id: client.id) { query }
      expect(response.status).to eq(200), result.inspect
      codes = result.dig('data', 'client', 'scanCardCodes', 'nodes').map { |n| n['code'] }
      expect(codes).to contain_exactly(code1.code, code2.code)
    end
  end

  describe 'scan code mutations' do
    let(:create_code) do
      <<~GRAPHQL
        mutation CreateScanCard($id: ID!) {
          createScanCardCode(clientId: $id) {
            scanCardCode {
              id
              code
            }
          }
        }
      GRAPHQL
    end

    let(:delete_code) do
      <<~GRAPHQL
        mutation DeleteScanCard($id: ID!) {
          deleteScanCardCode(id: $id) {
            scanCardCode {
              id
              code
            }
          }
        }
      GRAPHQL
    end

    let(:restore_code) do
      <<~GRAPHQL
        mutation RestoreScanCard($id: ID!) {
          restoreScanCardCode(id: $id) {
            scanCardCode {
              id
              code
            }
          }
        }
      GRAPHQL
    end

    let!(:client) { create(:hmis_hud_client, data_source: ds1) }
    let!(:code1) { create(:hmis_scan_card_code, client: client) }

    before(:each) do
      add_permissions(access_control, :can_manage_scan_cards)
    end

    it 'requires permission for all mutations' do
      remove_permissions(access_control, :can_manage_scan_cards)

      expect_gql_error post_graphql(id: client.id) { create_code }
      expect_gql_error post_graphql(id: code1.id) { delete_code }
      expect_gql_error post_graphql(id: code1.id) { restore_code }
    end

    it 'creates codes' do
      codes = client.scan_card_codes
      expect do
        response, result = post_graphql(id: client.id) { create_code }
        expect(response.status).to eq(200), result.inspect
      end.to change(codes, :count).by(1)
    end

    it 'deletes codes' do
      response, result = post_graphql(id: code1.id) { delete_code }
      expect(response.status).to eq(200), result.inspect
      expect(code1.reload.deleted_at).to be_present
    end

    it 'restores codes' do
      code1.update(deleted_at: Time.current)
      response, result = post_graphql(id: code1.id) { restore_code }
      expect(response.status).to eq(200), result.inspect
      expect(code1.reload.deleted_at).to be_nil
    end
  end
end
