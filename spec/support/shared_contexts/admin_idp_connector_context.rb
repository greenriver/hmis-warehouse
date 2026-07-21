###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Common Keycloak/IdP scaffolding for the JWT-arm admin user specs: a creation-capable 'test'
# connector backed by DB credentials, a stubbed token endpoint, and WebMock net isolation.
# Including specs must `require 'webmock/rspec'` and sign in an admin themselves.
RSpec.shared_context 'with a creation-capable IdP connector' do
  let(:api_url) { 'http://keycloak.test:8080' }
  let(:realm) { 'openpath' }
  let(:connector_id) { 'test' } # matches JwtAuthenticationHelper#sign_in
  let(:token_url) { "#{api_url}/realms/#{realm}/protocol/openid-connect/token" }
  let(:users_url) { "#{api_url}/admin/realms/#{realm}/users" }

  before(:each) do
    # DB-managed Keycloak credentials for the 'test' connector so it resolves to a real
    # KeycloakService rather than a NullService and reports itself as creation-capable.
    create(
      :idp_service_config,
      connector_id: connector_id,
      provider: 'keycloak',
      api_url: api_url,
      keycloak_realm: realm,
    )

    WebMock.disable_net_connect!
    stub_request(:post, token_url).to_return(
      status: 200,
      body: { access_token: 'test-token', expires_in: 300 }.to_json,
      headers: { 'Content-Type' => 'application/json' },
    )
  end

  after(:each) do
    WebMock.reset!
    WebMock.allow_net_connect!
  end
end
