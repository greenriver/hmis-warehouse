###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../hmis/login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  let(:stub_aha) { double }
  let!(:aha_credential) do
    GrdaWarehouse::RemoteCredentials::ApiKey.first_or_create!(
      slug: 'ac_hmis_aha',
      active: true,
      endpoint: 'https://example.com',
      password: 'test-token',
      username: '',
    )
  end
  let!(:mci_unique_id) { create(:mci_unique_id_external_id, source: c1) }
  let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_view_clients]) }

  before(:each) do
    hmis_login(user)
    allow(HmisExternalApis::AcHmis::Aha).to receive(:new).and_return(stub_aha)
  end

  let(:mutation) do
    <<~GRAPHQL
      mutation FetchAhaScore($clientId: ID!, $lookupCatalyst: String, $lookupReason: [String!]) {
        fetchAhaScore(clientId: $clientId, lookupCatalyst: $lookupCatalyst, lookupReason: $lookupReason) {
          score
          mciQualityIndicator
          dwClientId
          generator
          ahaFailedReason
          #{error_fields}
        }
      }
    GRAPHQL
  end

  def perform_mutation(client_id:, lookup_catalyst: nil, lookup_reason: nil)
    response, result = post_graphql(client_id: client_id, lookup_catalyst: lookup_catalyst, lookup_reason: lookup_reason) { mutation }

    aggregate_failures 'checking response' do
      expect(response.status).to eq 200
      data = result.dig('data', 'fetchAhaScore')
      errors = result.dig('data', 'fetchAhaScore', 'errors')
      yield data, errors
    end
  end

  context 'when AHA is enabled' do
    before do
      allow(HmisExternalApis::AcHmis::Aha).to receive(:enabled?).and_return(true)
    end

    context 'when client has MCI unique ID' do
      let(:aha_result) do
        OpenStruct.new(
          score: 8,
          mci_quality_indicator: 0,
          dw_client_id: mci_unique_id.value,
          generator: 'AHA',
        )
      end

      it 'returns AHA score successfully' do
        allow(stub_aha).to receive(:fetch_score).with(c1, lookup_catalyst: 'OCS Staff', lookup_reason: ['Other']).and_return(aha_result)

        perform_mutation(client_id: c1.id, lookup_catalyst: 'OCS Staff', lookup_reason: ['Other']) do |data, errors|
          expect(errors).to be_empty
          expect(data['score']).to eq(8)
          expect(data['mciQualityIndicator']).to eq(0)
          expect(data['dwClientId']).to eq(mci_unique_id.value)
          expect(data['generator']).to eq('AHA')
          expect(data['ahaFailedReason']).to be_nil
        end
      end

      it 'handles AHA score of -1' do
        aha_result_neg_one = OpenStruct.new(
          score: -1,
          mci_quality_indicator: 1,
          dw_client_id: mci_unique_id.value,
          generator: 'AHA',
        )
        allow(stub_aha).to receive(:fetch_score).with(c1, lookup_catalyst: nil, lookup_reason: nil).and_return(aha_result_neg_one)

        perform_mutation(client_id: c1.id) do |data, errors|
          expect(errors).to be_empty
          expect(data['score']).to eq(-1)
          expect(data['mciQualityIndicator']).to eq(1)
          expect(data['ahaFailedReason']).to be_nil
        end
      end
    end

    context 'when client has no MCI unique ID' do
      let!(:client_without_mci) { create(:hmis_hud_client, data_source: ds1, user: u1) }

      it 'returns score -1 with NO_MCI_UNIQUE_ID reason' do
        allow(stub_aha).to receive(:fetch_score).with(client_without_mci, lookup_catalyst: nil, lookup_reason: nil).
          and_raise(HmisExternalApis::AcHmis::Aha::NoMciUniqueIdError)

        perform_mutation(client_id: client_without_mci.id) do |data, errors|
          expect(errors).to be_empty
          expect(data['score']).to eq(-1)
          expect(data['ahaFailedReason']).to eq('NO_MCI_UNIQUE_ID')
          expect(data['mciQualityIndicator']).to be_nil
          expect(data['dwClientId']).to be_nil
          expect(data['generator']).to be_nil
        end
      end
    end

    context 'when client is not viewable' do
      let!(:access_control) { create_access_control(hmis_user, ds1, without_permission: [:can_view_clients]) }
      it 'returns access denied error' do
        expect_access_denied(post_graphql(client_id: c1.id) { mutation })
      end
    end

    context 'when client does not exist' do
      it 'returns access denied error' do
        expect_access_denied(post_graphql(client_id: '999999') { mutation })
      end
    end
  end

  context 'when AHA is not enabled' do
    before do
      allow(HmisExternalApis::AcHmis::Aha).to receive(:enabled?).and_return(false)
    end

    it 'returns server error' do
      perform_mutation(client_id: c1.id) do |data, errors|
        expect(data['score']).to be_nil
        expect(errors).to contain_exactly(
          include(
            'type' => 'server_error',
            'fullMessage' => 'AHA connection is not configured',
          ),
        )
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
