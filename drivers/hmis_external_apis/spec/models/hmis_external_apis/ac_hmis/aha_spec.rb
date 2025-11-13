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

  # Helper methods
  def score_hash(score:, generator:, alt_aha_flag:)
    {
      'score' => score,
      'metadata' => { 'alt_aha_flag' => alt_aha_flag },
      'generator' => generator,
    }
  end

  def client_data(dw_client_id:, scores:)
    {
      'dw_client_id' => dw_client_id,
      'scores' => scores,
    }
  end

  def mock_api_response(*client_data_hashes)
    double(
      'response',
      error: false,
      http_status: 200,
      parsed_body: { 'data' => client_data_hashes },
    )
  end

  def setup_api_expectation(mci_unique_ids:, response:)
    payload_key = mci_unique_ids.is_a?(Array) ? :dw_client_id__dw_client_id__overlap : :dw_client_id__dw_client_id__includes
    payload_value = mci_unique_ids.is_a?(Array) ? mci_unique_ids.join(',') : mci_unique_ids
    expect(mock_connection).to receive(:post).with('api/v1/clients/scores/search/', { payload_key => payload_value }).and_return(response)
  end

  context 'when client has no MCI unique ID' do
    it 'raises NoMciUniqueIdError' do
      expect { aha.fetch_score(client) }.to raise_error(HmisExternalApis::AcHmis::Aha::NoMciUniqueIdError)
    end
  end

  context 'when API returns "No client found" error' do
    let!(:mci_unique_id) { create(:mci_unique_id_external_id, source: client, remote_credential: remote_credential) }

    before do
      response = double(
        'response',
        error: false,
        http_status: 200,
        parsed_body: { 'result' => 'error', 'message' => 'No client found.', 'data' => [] },
      )
      setup_api_expectation(mci_unique_ids: mci_unique_id.value, response: response)
    end

    it 'raises NoMciUniqueIdError' do
      expect { aha.fetch_score(client) }.to raise_error(HmisExternalApis::AcHmis::Aha::NoMciUniqueIdError)
    end
  end

  context 'when client has MCI unique ID' do
    let!(:mci_unique_id) { create(:mci_unique_id_external_id, source: client, remote_credential: remote_credential) }

    before do
      response = mock_api_response(
        client_data(
          dw_client_id: mci_unique_id.value,
          scores: [
            score_hash(score: 8, generator: 'AHA', alt_aha_flag: 0),
            score_hash(score: 10, generator: 'MH-AHA', alt_aha_flag: 0),
          ],
        ),
      )
      setup_api_expectation(mci_unique_ids: mci_unique_id.value, response: response)
    end

    it 'calls API and returns the highest AHA score, disregarding other generators' do
      result = aha.fetch_score(client)
      expect(result.score).to eq(8)
      expect(result.dw_client_id).to eq(mci_unique_id.value)
    end
  end

  context 'when response contains multiple AHA scores' do
    let!(:mci_unique_id) { create(:mci_unique_id_external_id, source: client, remote_credential: remote_credential) }

    before do
      response = mock_api_response(
        client_data(
          dw_client_id: mci_unique_id.value,
          scores: [
            score_hash(score: 3, generator: 'AHA', alt_aha_flag: 0),
            score_hash(score: 7, generator: 'AHA', alt_aha_flag: 1),
            score_hash(score: 5, generator: 'AHA', alt_aha_flag: 0),
            score_hash(score: 10, generator: 'MH-AHA', alt_aha_flag: 0),
          ],
        ),
      )
      setup_api_expectation(mci_unique_ids: mci_unique_id.value, response: response)
    end

    it 'returns the highest AHA score and preserves all fields including metadata' do
      result = aha.fetch_score(client)
      expect(result.score).to eq(7) # Highest AHA score (not 10, which is MH-AHA)
      expect(result.generator).to eq('AHA')
      expect(result.mci_quality_indicator).to eq(1) # From the highest AHA score
      expect(result.dw_client_id).to eq(mci_unique_id.value)
    end
  end

  context 'when AHA score is -1' do
    let!(:mci_unique_id) { create(:mci_unique_id_external_id, source: client, remote_credential: remote_credential) }

    before do
      response = mock_api_response(
        client_data(
          dw_client_id: mci_unique_id.value,
          scores: [score_hash(score: -1, generator: 'AHA', alt_aha_flag: 1)],
        ),
      )
      setup_api_expectation(mci_unique_ids: mci_unique_id.value, response: response)
    end

    it 'returns all fields including generator and metadata when score is -1' do
      result = aha.fetch_score(client)
      expect(result.score).to eq(-1)
      expect(result.generator).to eq('AHA')
      expect(result.mci_quality_indicator).to eq(1)
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
      response = mock_api_response(
        client_data(dw_client_id: mci_unique_id1.value, scores: [score_hash(score: 6, generator: 'AHA', alt_aha_flag: 0)]),
        client_data(dw_client_id: mci_unique_id2.value, scores: [score_hash(score: 9, generator: 'AHA', alt_aha_flag: 1)]),
      )
      setup_api_expectation(mci_unique_ids: [mci_unique_id1.value, mci_unique_id2.value], response: response)
    end

    it 'calls API with comma-separated list of all sibling MCI IDs' do
      result = aha.fetch_score(client)
      expect(result.score).to eq(9) # Returns the highest score
      expect(result.mci_quality_indicator).to eq(1)
    end
  end

  context 'when client has siblings with multiple AHA scores' do
    let!(:client) { create(:hmis_hud_client_with_warehouse_client, data_source: data_source) }

    let!(:sibling1) { create(:hmis_hud_client, data_source: data_source) }
    let!(:sibling2) { create(:hmis_hud_client, data_source: data_source) }
    let!(:sibling3) { create(:hmis_hud_client, data_source: data_source) }

    let!(:warehouse_client1) { create(:hmis_warehouse_client, source: sibling1, destination: client.destination_client, data_source: data_source) }
    let!(:warehouse_client2) { create(:hmis_warehouse_client, source: sibling2, destination: client.destination_client, data_source: data_source) }
    let!(:warehouse_client3) { create(:hmis_warehouse_client, source: sibling3, destination: client.destination_client, data_source: data_source) }

    let!(:mci_unique_id1) { create(:mci_unique_id_external_id, source: sibling1, remote_credential: remote_credential) }
    let!(:mci_unique_id2) { create(:mci_unique_id_external_id, source: sibling2, remote_credential: remote_credential) }
    let!(:mci_unique_id3) { create(:mci_unique_id_external_id, source: sibling3, remote_credential: remote_credential) }

    before do
      response = mock_api_response(
        client_data(
          dw_client_id: mci_unique_id1.value,
          scores: [
            score_hash(score: 4, generator: 'AHA', alt_aha_flag: 0),
            score_hash(score: 8, generator: 'AHA', alt_aha_flag: 0),
          ],
        ),
        client_data(
          dw_client_id: mci_unique_id2.value,
          scores: [
            score_hash(score: 2, generator: 'AHA', alt_aha_flag: 1),
            score_hash(score: 6, generator: 'AHA', alt_aha_flag: 0),
            score_hash(score: 10, generator: 'MH-AHA', alt_aha_flag: 0),
          ],
        ),
        client_data(
          dw_client_id: mci_unique_id3.value,
          scores: [score_hash(score: 9, generator: 'AHA', alt_aha_flag: 1)],
        ),
      )
      setup_api_expectation(mci_unique_ids: [mci_unique_id1.value, mci_unique_id2.value, mci_unique_id3.value], response: response)
    end

    it 'returns the highest AHA score across all siblings' do
      result = aha.fetch_score(client)
      expect(result.score).to eq(9) # Highest AHA score across all clients (not 10 which is MH-AHA)
      expect(result.generator).to eq('AHA')
      expect(result.mci_quality_indicator).to eq(1) # From the highest scoring AHA entry
      expect(result.dw_client_id).to eq(mci_unique_id3.value) # From the client with the highest score
    end
  end

  context 'when response does not contain AHA score' do
    let!(:mci_unique_id) { create(:mci_unique_id_external_id, source: client, remote_credential: remote_credential) }

    before do
      response = mock_api_response(
        client_data(
          dw_client_id: mci_unique_id.value,
          scores: [score_hash(score: 10, generator: 'MH-AHA', alt_aha_flag: 0)],
        ),
      )
      setup_api_expectation(mci_unique_ids: mci_unique_id.value, response: response)
    end

    it 'raises Error with message about missing AHA score' do
      expect { aha.fetch_score(client) }.to raise_error(HmisErrors::ApiError, /does not contain AHA score/)
    end
  end

  context 'when AHA score is invalid' do
    let!(:mci_unique_id) { create(:mci_unique_id_external_id, source: client, remote_credential: remote_credential) }

    [-2, 0, 1.5, 11, 'str'].each do |invalid_score|
      it "raises Error with message about invalid AHA score (#{invalid_score})" do
        response = mock_api_response(
          client_data(
            dw_client_id: mci_unique_id.value,
            scores: [score_hash(score: invalid_score, generator: 'AHA', alt_aha_flag: 0)],
          ),
        )
        setup_api_expectation(mci_unique_ids: mci_unique_id.value, response: response)

        expect { aha.fetch_score(client) }.to raise_error(HmisErrors::ApiError, /Received invalid score/)
      end
    end
  end
end
