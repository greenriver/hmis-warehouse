###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

# CAUTION: This is not part of the normal test suite. It runs against a live remote endpoint
# We need many secrets to test this. Essentially, this runs locally or on staging
RSpec.describe 'MCI API', type: :model do
  if ENV['OAUTH_CREDENTIAL_TEST'] == 'true'
    let(:creds) do
      create(
        :grda_remote_oauth_credential,
        client_id: ENV.fetch('MCI_CLIENT_ID'),
        client_secret: ENV.fetch('MCI_CLIENT_SECRET'),
        token_url: ENV.fetch('MCI_TOKEN_URL'),
        additional_headers: { 'Ocp-Apim-Subscription-Key' => ENV.fetch('MCI_OCP_APIM_SUBSCRIPTION_KEY') },
        base_url: "https://#{ENV.fetch('MCI_HOST')}/",
        oauth_scope: 'API_TEST',
      )
    end

    let(:subject) do
      HmisExternalApis::OauthClientConnection.new(creds)
    end

    it 'supports a get' do
      result = subject.get('clients/v1/api/Lookup/logicalTables')
      expect(result.http_status).to eq(200)
      expect(result.parsed_body).to include('COUNTRY')
      expect(result.parsed_body).to include('RACE')
    end

    it 'handles errors' do
      result = subject.get('clients/v1/api/not-a-thing')
      expect(result.http_status).to eq(404)
      expect(result.parsed_body).to be_nil
      expect(result.error_type).to eq('OAuth2::Error')
    end

    it 'supports a post' do
      result = subject.post('clients/v1/api/Clients/clearance', { 'firstName' => 'John', 'lastName' => 'Smith', 'genderCode' => 1 })
      expect(result.http_status).to eq(200)
      expect(result.parsed_body.length).to be >= 450
    end
  end
end
