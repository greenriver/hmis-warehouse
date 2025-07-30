###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisExternalApis::AcHmis::Aha, type: :model do
  let!(:data_source) { create :hmis_primary_data_source }
  let!(:client) { create(:hmis_hud_client, data_source: data_source) }

  let!(:aha) { described_class.new }
  let!(:mock_connection) { double('connection') }
  let!(:remote_credential) { create(:ac_hmis_warehouse_credential) }

  before do
    # Mock the connection to avoid actual API calls
    allow(aha).to receive(:conn).and_return(mock_connection)
  end

  context 'when client has no MCI unique ID' do
    it 'returns nil' do
      expect(aha.fetch_score(client)).to be_nil
    end
  end

  context 'when client has MCI unique ID' do
    let!(:mci_unique_id) { create(:mci_unique_id_external_id, source: client, remote_credential: remote_credential) }

    before do
      # Mock successful API response
      mock_response = double(
        'response',
        error: false,
        http_status: 200,
        parsed_body: {
          'data' => [
            {
              'dw_client_id' => mci_unique_id.value,
              'scores' => [
                {
                  'score' => 8,
                  'metadata' => { 'alt_aha_flag' => 0 },
                  'generator' => 'test_generator',
                },
              ],
            },
          ],
        },
      )

      expect(mock_connection).to receive(:post).with('api/v1/clients/scores/search/', { 'dw_client_id': mci_unique_id.value }).and_return(mock_response)
    end

    it 'calls API with single MCI ID' do
      result = aha.fetch_score(client)
      expect(result.score).to eq(8)
      expect(result.dw_client_id).to eq(mci_unique_id.value)
    end
  end

  context 'when client has siblings with MCI unique IDs' do
    let!(:client) { create(:hmis_hud_client_with_warehouse_client, data_source: data_source) }

    let!(:sibling1) { create(:hmis_hud_client, data_source: data_source) }
    let!(:sibling2) { create(:hmis_hud_client, data_source: data_source) }
    let!(:sibling3) { create(:hmis_hud_client, data_source: data_source) }

    let!(:warehouse_client1) { create(:hmis_warehouse_client, source: sibling1, destination: client.destination_client, data_source: data_source) }
    let!(:warehouse_client2) { create(:hmis_warehouse_client, source: sibling2, destination: client.destination_client, data_source: data_source) }
    let!(:warehouse_client3) { create(:hmis_warehouse_client, source: sibling3, destination: client.destination_client, data_source: data_source) }

    # client doesn't have mci_unique_id, but some of its siblings do
    let!(:mci_unique_id1) { create(:mci_unique_id_external_id, source: sibling1, remote_credential: remote_credential) }
    let!(:mci_unique_id2) { create(:mci_unique_id_external_id, source: sibling2, remote_credential: remote_credential) }

    before do
      # Mock successful API response
      mock_response = double(
        'response',
        error: false,
        http_status: 200,
        parsed_body: {
          'data' => [
            {
              'dw_client_id' => mci_unique_id1.value,
              'scores' => [
                {
                  'score' => 6,
                  'metadata' => { 'alt_aha_flag' => 0 },
                  'generator' => 'test_generator',
                },
              ],
            },
            {
              'dw_client_id' => mci_unique_id2.value,
              'scores' => [
                {
                  'score' => 9,
                  'metadata' => { 'alt_aha_flag' => 1 },
                  'generator' => 'test_generator',
                },
              ],
            },
          ],
        },
      )

      expect(mock_connection).to receive(:post).with('api/v1/clients/scores/search/', { 'dw_client_id': "#{mci_unique_id1.value},#{mci_unique_id2.value}" }).and_return(mock_response)
    end

    it 'calls API with comma-separated list of all sibling MCI IDs' do
      result = aha.fetch_score(client)
      expect(result.score).to eq(9) # Returns the highest score
      expect(result.alt_aha_flag).to be true
    end
  end
end
