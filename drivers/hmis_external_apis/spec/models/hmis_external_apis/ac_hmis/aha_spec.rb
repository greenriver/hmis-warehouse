###
# Copyright Green River Data Group, Inc.
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

  # Helper methods for mocking score values returned by API
  def aha_score_hash(score:, generator: 'AHA', alt_aha_flag: nil, metadata: nil)
    {
      'score' => score,
      'metadata' => metadata || { 'alt_aha_flag' => alt_aha_flag }.compact,
      'generator' => generator,
    }
  end

  def mh_aha_score_hash(score:, generator: 'MH-AHA', metadata: nil)
    {
      'score' => score,
      'metadata' => metadata || { 'row_id' => '1', 'run_id' => 'aha_abc', 'mci_uniq_id' => '100000022' },
      'generator' => generator,
    }
  end

  def visionlink_score_hash(score:, generator: 'VisionLink', metadata: nil)
    {
      'score' => score,
      'generator' => generator,
      'metadata' => metadata || {
        'row_id' => '1',
        'run_id' => 'rental_assistance_abcde',
        'is_eligible_ra' => false,
        'currently_unhoused' => false,
        'is_eligible_cc' => true,
        'mci_uniq_id' => '100000022',
        'homeless_risk' => 0,
        'section_8' => 0,
        'city_of_pittsburgh' => 0,
        'subsidized_housing' => 0,
        'recent_erap_use' => 0,
      },
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

  def setup_api_expectation(mci_unique_ids:, response:, lookup_catalyst: nil, lookup_reason: nil)
    mci_key = mci_unique_ids.is_a?(Array) ? :dw_client_id__dw_client_id__overlap : :dw_client_id__dw_client_id__includes
    mci_value = mci_unique_ids.is_a?(Array) ? mci_unique_ids.join(',') : mci_unique_ids

    expected_payload = {
      mci_key => mci_value,
    }
    expected_payload[:lookup_catalyst] = lookup_catalyst if lookup_catalyst.present?
    expected_payload[:lookup_reason] = lookup_reason if lookup_reason&.any?

    expect(mock_connection).to receive(:post).with('api/v1/clients/scores/search/', expected_payload).and_return(response)
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

    let!(:response) do
      mock_api_response(
        client_data(
          dw_client_id: mci_unique_id.value,
          scores: [
            aha_score_hash(score: 8, alt_aha_flag: 0),
            mh_aha_score_hash(score: 10),
          ],
        ),
      )
    end

    it 'calls API and returns the highest AHA score, disregarding other generators' do
      setup_api_expectation(mci_unique_ids: mci_unique_id.value, response: response)

      result = aha.fetch_score(client)[:aha]
      expect(result.score).to eq(8)
      expect(result.dw_client_id).to eq(mci_unique_id.value)
      expect(result).to be_a(HmisExternalApis::AcHmis::AhaScores::AhaResult)
    end

    it 'calls API with lookup catalyst and reason when provided' do
      setup_api_expectation(mci_unique_ids: mci_unique_id.value, response: response, lookup_catalyst: 'OCS Staff', lookup_reason: ['Other'])

      result = aha.fetch_score(client, lookup_catalyst: 'OCS Staff', lookup_reason: ['Other'])[:aha]
      expect(result.score).to eq(8)
    end

    it 'ignores invalid values for lookup catalyst and reason' do
      allow(Sentry).to receive(:capture_message)
      setup_api_expectation(mci_unique_ids: mci_unique_id.value, response: response)

      result = aha.fetch_score(client, lookup_catalyst: 'random text', lookup_reason: ['not a good reason'])[:aha]
      expect(result.score).to eq(8)

      expect(Sentry).to have_received(:capture_message).with('AHA received unexpected lookup catalyst: random text')
      expect(Sentry).to have_received(:capture_message).with('AHA received unexpected lookup reason(s): not a good reason')
    end
  end

  context 'when response contains multiple AHA scores' do
    let!(:mci_unique_id) { create(:mci_unique_id_external_id, source: client, remote_credential: remote_credential) }

    before do
      response = mock_api_response(
        client_data(
          dw_client_id: mci_unique_id.value,
          scores: [
            aha_score_hash(score: 3, alt_aha_flag: 0),
            aha_score_hash(score: 7, alt_aha_flag: 1),
            aha_score_hash(score: 5, alt_aha_flag: 0),
            mh_aha_score_hash(score: 10),
          ],
        ),
      )
      setup_api_expectation(mci_unique_ids: mci_unique_id.value, response: response)
    end

    it 'returns the highest AHA score and preserves all fields including metadata' do
      result = aha.fetch_score(client)[:aha]
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
          scores: [aha_score_hash(score: -1, alt_aha_flag: 1)],
        ),
      )
      setup_api_expectation(mci_unique_ids: mci_unique_id.value, response: response)
    end

    it 'returns all fields including generator and metadata when score is -1' do
      result = aha.fetch_score(client)[:aha]
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
        client_data(dw_client_id: mci_unique_id1.value, scores: [aha_score_hash(score: 6, alt_aha_flag: 0)]),
        client_data(dw_client_id: mci_unique_id2.value, scores: [aha_score_hash(score: 9, alt_aha_flag: 1)]),
      )
      setup_api_expectation(mci_unique_ids: [mci_unique_id1.value, mci_unique_id2.value], response: response)
    end

    it 'calls API with comma-separated list of all sibling MCI IDs' do
      result = aha.fetch_score(client)[:aha]
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
            aha_score_hash(score: 4, alt_aha_flag: 0),
            aha_score_hash(score: 8, alt_aha_flag: 0),
          ],
        ),
        client_data(
          dw_client_id: mci_unique_id2.value,
          scores: [
            aha_score_hash(score: 2, alt_aha_flag: 1),
            aha_score_hash(score: 6, alt_aha_flag: 0),
            mh_aha_score_hash(score: 10),
          ],
        ),
        client_data(
          dw_client_id: mci_unique_id3.value,
          scores: [aha_score_hash(score: 9, alt_aha_flag: 1)],
        ),
      )
      setup_api_expectation(mci_unique_ids: [mci_unique_id1.value, mci_unique_id2.value, mci_unique_id3.value], response: response)
    end

    it 'returns the highest AHA score across all siblings' do
      result = aha.fetch_score(client)[:aha]
      expect(result.score).to eq(9) # Highest AHA score across all clients (not 10 which is MH-AHA)
      expect(result.generator).to eq('AHA')
      expect(result.mci_quality_indicator).to eq(1) # From the highest scoring AHA entry
      expect(result.dw_client_id).to eq(mci_unique_id3.value) # From the client with the highest score
    end
  end

  context 'when AHA score is invalid' do
    let!(:mci_unique_id) { create(:mci_unique_id_external_id, source: client, remote_credential: remote_credential) }

    [-2, 0, 1.5, 11, 'str'].each do |invalid_score|
      it "logs to Sentry and returns nil for AHA when sole AHA requested (#{invalid_score})" do
        allow(Sentry).to receive(:capture_message)
        response = mock_api_response(
          client_data(
            dw_client_id: mci_unique_id.value,
            scores: [aha_score_hash(score: invalid_score, alt_aha_flag: 0)],
          ),
        )
        setup_api_expectation(mci_unique_ids: mci_unique_id.value, response: response)

        expect(aha.fetch_score(client)[:aha]).to be_nil
        expect(Sentry).to have_received(:capture_message).with(/AHA received invalid AHA score entry/)
      end
    end
  end

  context 'when generators are case-insensitive' do
    let!(:mci_unique_id) { create(:mci_unique_id_external_id, source: client, remote_credential: remote_credential) }

    before do
      response = mock_api_response(
        client_data(
          dw_client_id: mci_unique_id.value,
          scores: [
            aha_score_hash(score: 5, generator: 'aha', alt_aha_flag: 0),
            mh_aha_score_hash(score: 7, generator: 'mh-aha'),
            visionlink_score_hash(score: 3.5, generator: 'VISIONLINK'),
          ],
        ),
      )
      setup_api_expectation(mci_unique_ids: mci_unique_id.value, response: response)
    end

    it 'parses mixed-case generator values' do
      results = aha.fetch_score(client, requested_generators: [:aha, :mh_aha, :visionlink])

      expect(results[:aha].score).to eq(5)
      expect(results[:mh_aha].score).to eq(7)
      expect(results[:visionlink].score).to eq(3.5)
    end
  end

  context 'when requesting MH-AHA scores' do
    let!(:mci_unique_id) { create(:mci_unique_id_external_id, source: client, remote_credential: remote_credential) }

    it 'returns the highest MH-AHA score across entries' do
      response = mock_api_response(
        client_data(
          dw_client_id: mci_unique_id.value,
          scores: [
            mh_aha_score_hash(score: 3),
            mh_aha_score_hash(score: 7),
            aha_score_hash(score: 9, alt_aha_flag: 0),
          ],
        ),
      )
      setup_api_expectation(mci_unique_ids: mci_unique_id.value, response: response)

      results = aha.fetch_score(client, requested_generators: [:mh_aha])
      expect(results[:mh_aha].score).to eq(7)
      expect(results[:mh_aha]).to be_a(HmisExternalApis::AcHmis::AhaScores::MhAhaResult)
    end

    it 'returns the highest AHA and MH-AHA scores across clients' do
      response = mock_api_response(
        client_data(
          dw_client_id: mci_unique_id.value,
          scores: [
            mh_aha_score_hash(score: 7),
            aha_score_hash(score: 3, alt_aha_flag: 0),
          ],
        ),
        client_data(
          dw_client_id: mci_unique_id.value,
          scores: [
            mh_aha_score_hash(score: 2),
            aha_score_hash(score: 9, alt_aha_flag: 0),
          ],
        ),
      )
      setup_api_expectation(mci_unique_ids: mci_unique_id.value, response: response)

      results = aha.fetch_score(client, requested_generators: [:mh_aha, :aha])
      expect(results[:mh_aha].score).to eq(7) # highest across clients (2,7)
      expect(results[:aha].score).to eq(9) # highest across clients (3,9)
    end

    it 'returns nil when MH-AHA is missing but AHA is requested' do
      response = mock_api_response(
        client_data(
          dw_client_id: mci_unique_id.value,
          scores: [aha_score_hash(score: 8, alt_aha_flag: 0)],
        ),
      )
      setup_api_expectation(mci_unique_ids: mci_unique_id.value, response: response)

      results = aha.fetch_score(client, requested_generators: [:aha, :mh_aha])
      expect(results[:aha].score).to eq(8)
      expect(results[:mh_aha]).to be_nil
    end

    [-2, 0, 11, 'str'].each do |invalid_score|
      it "skips invalid MH-AHA score (#{invalid_score}) and logs to Sentry" do
        allow(Sentry).to receive(:capture_message)
        response = mock_api_response(
          client_data(
            dw_client_id: mci_unique_id.value,
            scores: [
              mh_aha_score_hash(score: invalid_score),
              mh_aha_score_hash(score: 6),
            ],
          ),
        )
        setup_api_expectation(mci_unique_ids: mci_unique_id.value, response: response)

        results = aha.fetch_score(client, requested_generators: [:mh_aha])
        expect(results[:mh_aha].score).to eq(6)
        expect(Sentry).to have_received(:capture_message).with(/AHA received invalid MH-AHA score entry/)
      end
    end
  end

  context 'when requesting VisionLink scores' do
    let!(:mci_unique_id) { create(:mci_unique_id_external_id, source: client, remote_credential: remote_credential) }

    it 'returns typed VisionLink metadata with a numeric score' do
      response = mock_api_response(
        client_data(
          dw_client_id: mci_unique_id.value,
          scores: [visionlink_score_hash(score: 4.25)],
        ),
      )
      setup_api_expectation(mci_unique_ids: mci_unique_id.value, response: response)

      result = aha.fetch_score(client, requested_generators: [:visionlink])[:visionlink]
      expect(result.score).to eq(4.25)
      expect(result.is_eligible_ra).to eq(false)
      expect(result.is_eligible_cc).to eq(true)
      expect(result.homeless_risk).to eq(0)
      expect(result).to be_a(HmisExternalApis::AcHmis::AhaScores::VisionLinkResult)
    end

    it 'returns -999 score with flags when no real score exists' do
      response = mock_api_response(
        client_data(
          dw_client_id: mci_unique_id.value,
          scores: [visionlink_score_hash(score: -999)],
        ),
      )
      setup_api_expectation(mci_unique_ids: mci_unique_id.value, response: response)

      result = aha.fetch_score(client, requested_generators: [:visionlink])[:visionlink]
      expect(result.score).to eq(-999)
      expect(result.is_eligible_ra).to eq(false)
      expect(result.is_eligible_cc).to eq(true)
    end

    it 'prefers the highest score when both -999 and a real score are present' do
      response = mock_api_response(
        client_data(
          dw_client_id: mci_unique_id.value,
          scores: [
            visionlink_score_hash(score: -999),
            visionlink_score_hash(score: 3.5),
          ],
        ),
      )
      setup_api_expectation(mci_unique_ids: mci_unique_id.value, response: response)

      result = aha.fetch_score(client, requested_generators: [:visionlink])[:visionlink]
      expect(result.score).to eq(3.5)
    end
  end

  context 'when requesting multiple generators' do
    let!(:mci_unique_id) { create(:mci_unique_id_external_id, source: client, remote_credential: remote_credential) }

    it 'returns populated keys and nil for missing requested generators' do
      response = mock_api_response(
        client_data(
          dw_client_id: mci_unique_id.value,
          scores: [
            aha_score_hash(score: 8, alt_aha_flag: 0),
            mh_aha_score_hash(score: 5),
          ],
        ),
      )
      setup_api_expectation(mci_unique_ids: mci_unique_id.value, response: response)

      results = aha.fetch_score(client, requested_generators: [:aha, :mh_aha, :visionlink])
      expect(results[:aha].score).to eq(8)
      expect(results[:mh_aha].score).to eq(5)
      expect(results[:visionlink]).to be_nil
    end

    it 'returns MH-AHA when AHA entry is invalid' do
      allow(Sentry).to receive(:capture_message)
      response = mock_api_response(
        client_data(
          dw_client_id: mci_unique_id.value,
          scores: [
            aha_score_hash(score: 0, alt_aha_flag: 0),
            mh_aha_score_hash(score: 6),
          ],
        ),
      )
      setup_api_expectation(mci_unique_ids: mci_unique_id.value, response: response)

      results = aha.fetch_score(client, requested_generators: [:aha, :mh_aha])
      expect(results[:aha]).to be_nil
      expect(results[:mh_aha].score).to eq(6)
      expect(Sentry).to have_received(:capture_message).with(/AHA received invalid AHA score entry/)
    end
  end

  context 'when response contains unknown generators' do
    let!(:mci_unique_id) { create(:mci_unique_id_external_id, source: client, remote_credential: remote_credential) }

    it 'ignores unknown generators silently' do
      allow(Sentry).to receive(:capture_message)
      response = mock_api_response(
        client_data(
          dw_client_id: mci_unique_id.value,
          scores: [
            aha_score_hash(score: 8, alt_aha_flag: 0),
            aha_score_hash(score: 99, generator: 'UnknownGenerator', alt_aha_flag: 0),
          ],
        ),
      )
      setup_api_expectation(mci_unique_ids: mci_unique_id.value, response: response)

      result = aha.fetch_score(client)[:aha]
      expect(result.score).to eq(8)
      expect(Sentry).not_to have_received(:capture_message)
    end
  end
end
