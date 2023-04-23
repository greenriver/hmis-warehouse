###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require 'webmock/rspec'

# CAUTION: This is not part of the normal test suite. It runs against a live remote endpoint
# We need many secrets to test this. Essentially, this runs locally or on staging
RSpec.describe 'LINK API', type: :model do
  if ENV['OAUTH_CREDENTIAL_TEST'] == 'true'
    let(:host) { 'example.com' }
    let(:client_id) { ENV.fetch('LINK_CLIENT_ID') }
    let(:client_secret) { ENV.fetch('LINK_CLIENT_SECRET') }
    let(:token_url) { ENV.fetch('LINK_TOKEN_URL') }
    let(:oauth_scope) { 'GREEN_RIVER' }
    let(:ocp_apim_subscription_key) { ENV.fetch('LINK_OCP_APIM_SUBSCRIPTION_KEY') }

    let(:subject) do
      HmisExternalApis::OauthClientConnection.new(
        client_id: client_id,
        client_secret: client_secret,
        token_url: token_url,
        headers: { 'Ocp-Apim-Subscription-Key' => ocp_apim_subscription_key },
        base_url: "https://#{host}/",
        scope: oauth_scope,
      )
    end

    it 'supports a get' do
      # FIXME: the LINK API endpoints aren't built yet. This just tests auth
      path = 'test/resources/1'
      stub_request(:get, "#{subject.base_url}#{path}")
        .to_return(status: 200, body: nil, headers: { 'Content-Type' => 'application/json' })

      result = subject.get(path)
      expect(result.http_status).to eq(200)
    end
  end
end
