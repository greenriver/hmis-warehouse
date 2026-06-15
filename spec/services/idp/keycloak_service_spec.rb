###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'webmock/rspec'

RSpec.describe Idp::KeycloakService, type: :model do
  let(:api_url) { 'http://keycloak.test:8080' }
  let(:realm) { 'openpath' }
  let(:client_id) { 'rails-service-account' }
  let(:client_secret) { 'test-secret' }
  let(:token_url) { "#{api_url}/realms/#{realm}/protocol/openid-connect/token" }

  let(:service) do
    described_class.new(
      config: {
        api_url: api_url,
        realm: realm,
        client_id: client_id,
        client_secret: client_secret,
      },
    )
  end

  before do
    WebMock.disable_net_connect!
    stub_request(:post, token_url).
      to_return(
        status: 200,
        body: { access_token: 'test-token', expires_in: 300 }.to_json,
        headers: { 'Content-Type' => 'application/json' },
      )
  end

  after do
    WebMock.reset!
    WebMock.allow_net_connect!
  end

  describe '#create_user' do
    let(:user_email) { 'test@example.com' }

    context 'with valid user data' do
      before do
        stub_request(:post, "#{api_url}/admin/realms/#{realm}/users").
          to_return(
            status: 201,
            headers: { 'Location' => "#{api_url}/admin/realms/#{realm}/users/new-user-id" },
          )
      end

      it 'creates user and returns success with user ID' do
        result = service.create_user(
          email: user_email,
          first_name: 'John',
          last_name: 'Doe',
        )

        expect(result[:success]).to be true
        expect(result[:connector_user_id]).to eq('new-user-id')
      end

      it 'sends the Keycloak user payload with the expected field mapping' do
        service.create_user(
          email: user_email,
          first_name: 'John',
          last_name: 'Doe',
        )

        expect(
          a_request(:post, "#{api_url}/admin/realms/#{realm}/users").
            with(
              headers: { 'Authorization' => 'Bearer test-token' },
              body: {
                username: user_email,
                email: user_email,
                firstName: 'John',
                lastName: 'Doe',
                enabled: true,
                emailVerified: false,
              },
            ),
        ).to have_been_made
      end
    end

    context 'with API error response' do
      before do
        stub_request(:post, "#{api_url}/admin/realms/#{realm}/users").
          to_return(
            status: 409,
            body: { errorMessage: 'User exists with same username' }.to_json,
          )
      end

      it 'raises ServiceError' do
        expect do
          service.create_user(
            email: user_email,
            first_name: 'John',
            last_name: 'Doe',
          )
        end.to raise_error(Idp::ServiceError)
      end
    end
  end

  describe '#update_user' do
    let(:user_id) { 'keycloak-user-id' }

    context 'with successful update' do
      before do
        stub_request(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(status: 204)
      end

      it 'returns true and sends the mapped attributes' do
        result = service.update_user(
          user_id: user_id,
          attributes: { first_name: 'Jane' },
        )

        expect(result).to be true
        expect(
          a_request(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
            with(body: { firstName: 'Jane' }),
        ).to have_been_made
      end

      it 'sets emailVerified to false when the email changes' do
        service.update_user(
          user_id: user_id,
          attributes: { email: 'new@example.com' },
        )

        expect(
          a_request(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
            with(body: { email: 'new@example.com', emailVerified: false }),
        ).to have_been_made
      end
    end

    context 'with unknown attributes' do
      it 'raises ArgumentError' do
        expect do
          service.update_user(
            user_id: user_id,
            attributes: { first_name: 'Jane', phone: '555-1234' },
          )
        end.to raise_error(ArgumentError, /phone/)
      end
    end

    context 'with empty attributes' do
      it 'returns true without making a request' do
        result = service.update_user(user_id: user_id, attributes: {})

        expect(result).to be true
        expect(WebMock).not_to have_requested(:put, /#{Regexp.escape(api_url)}/)
      end
    end

    context 'with API error' do
      before do
        stub_request(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(
            status: 400,
            body: { errorMessage: 'Invalid attribute' }.to_json,
          )
      end

      it 'raises ServiceError' do
        expect do
          service.update_user(
            user_id: user_id,
            attributes: { first_name: 'Jane' },
          )
        end.to raise_error(Idp::ServiceError)
      end
    end
  end

  describe '#get_user' do
    let(:user_id) { 'keycloak-user-id' }

    context 'with successful response' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(
            status: 200,
            body: { id: user_id, username: 'test@example.com' }.to_json,
          )
      end

      it 'returns user data' do
        result = service.get_user(user_id: user_id)

        expect(result).to include('id' => user_id)
      end
    end

    context 'when user not found' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(status: 404)
      end

      it 'raises ServiceError' do
        expect do
          service.get_user(user_id: user_id)
        end.to raise_error(Idp::ServiceError)
      end
    end
  end

  describe '#reactivate_user' do
    let(:user_id) { 'keycloak-user-id' }

    context 'with successful reactivation' do
      before do
        stub_request(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(status: 204)
      end

      it 'returns true and enables the user' do
        result = service.reactivate_user(user_id: user_id)

        expect(result).to be true
        expect(
          a_request(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
            with(body: { enabled: true }),
        ).to have_been_made
      end
    end

    context 'with API error' do
      before do
        stub_request(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(
            status: 404,
            body: { error: 'User not found' }.to_json,
          )
      end

      it 'raises ServiceError' do
        expect do
          service.reactivate_user(user_id: user_id)
        end.to raise_error(Idp::ServiceError)
      end
    end
  end

  describe '#test_connection' do
    context 'with successful connection' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}").
          to_return(
            status: 200,
            body: { realm: realm }.to_json,
          )
      end

      it 'returns success result' do
        result = service.test_connection

        expect(result[:success]).to be true
        expect(result[:message]).to include('Connection successful')
      end
    end

    context 'with authentication failure' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}").
          to_return(status: 401)
      end

      it 'returns failure with auth message' do
        result = service.test_connection

        expect(result[:success]).to be false
        expect(result[:message]).to include('Authentication failed')
      end
    end

    context 'with connection refused' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}").
          to_raise(Errno::ECONNREFUSED)
      end

      it 'returns failure with connection message' do
        result = service.test_connection

        expect(result[:success]).to be false
        expect(result[:message]).to include('Connection refused')
      end
    end

    context 'with timeout' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}").
          to_timeout
      end

      it 'returns failure with timeout message' do
        result = service.test_connection

        expect(result[:success]).to be false
        expect(result[:message]).to include('timeout')
      end
    end
  end

  describe 'token retry on 401' do
    let(:user_id) { 'keycloak-user-id' }

    it 'retries once with a fresh token when API returns 401' do
      stub_request(:get, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
        to_return(
          { status: 401, body: { error: 'invalid_token' }.to_json },
          { status: 200, body: { id: user_id, username: 'test@example.com' }.to_json },
        )

      result = service.get_user(user_id: user_id)

      expect(result).to include('id' => user_id)
      expect(a_request(:post, token_url)).to have_been_made.times(2)
    end

    it 'does not retry more than once' do
      stub_request(:get, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
        to_return(status: 401, body: { error: 'invalid_token' }.to_json)

      expect do
        service.get_user(user_id: user_id)
      end.to raise_error(Idp::ServiceError, /Failed to get user/)
      expect(a_request(:post, token_url)).to have_been_made.times(2)
    end
  end

  describe '#idp_name' do
    it 'returns Keycloak' do
      expect(service.idp_name).to eq('Keycloak')
    end
  end

  describe '#supports_user_management?' do
    it 'returns true when fully configured' do
      expect(service.supports_user_management?).to be true
    end
  end

  describe 'config validation' do
    it 'raises on missing api_url' do
      expect do
        described_class.new(config: { client_id: 'x', client_secret: 'y' })
      end.to raise_error(Idp::ServiceError, /api_url/)
    end

    it 'raises on missing realm (no default)' do
      expect do
        described_class.new(config: { api_url: 'http://kc:8080', client_id: 'x', client_secret: 'y' })
      end.to raise_error(Idp::ServiceError, /realm/)
    end

    it 'raises on missing client_id' do
      expect do
        described_class.new(config: { api_url: 'http://kc:8080', realm: 'r', client_secret: 'y' })
      end.to raise_error(Idp::ServiceError, /client_id/)
    end

    it 'raises on missing client_secret' do
      expect do
        described_class.new(config: { api_url: 'http://kc:8080', realm: 'r', client_id: 'x' })
      end.to raise_error(Idp::ServiceError, /client_secret/)
    end

    it 'lists all missing keys' do
      expect do
        described_class.new(config: {})
      end.to raise_error(Idp::ServiceError, /api_url, realm, client_id, client_secret/)
    end
  end

  describe '.from_config' do
    # Mirrors the Idp::ServiceConfig reader surface that .from_config consumes
    # (api_url, client_id, service_token, keycloak_realm) without needing the DB
    # or encryption key. ServiceConfig's own columns are covered by its spec.
    let(:persisted_config) do
      Struct.new(:api_url, :client_id, :service_token, :keycloak_realm, keyword_init: true).new(
        api_url: 'http://kc.from-config:8080',
        client_id: 'config-client',
        service_token: 'config-secret',
        keycloak_realm: 'config-realm',
      )
    end

    it 'translates persisted storage columns into the service config keys' do
      service = described_class.from_config(persisted_config)

      expect(service.config).to include(
        api_url: 'http://kc.from-config:8080',
        client_id: 'config-client',
        client_secret: 'config-secret',
        realm: 'config-realm',
      )
    end
  end

  describe '#supports_profile_updates?' do
    it 'returns true' do
      expect(service.supports_profile_updates?).to be true
    end
  end

  describe '#account_console_url' do
    it 'builds the Account Console URL for the realm' do
      expect(service.account_console_url).to eq("#{api_url}/realms/#{realm}/account")
    end

    context 'when API URL is not configured' do
      before do
        service.config[:api_url] = nil
      end

      it 'returns nil' do
        expect(service.account_console_url).to be_nil
      end
    end
  end

  describe '#logout_url' do
    it 'generates logout URL with post_logout_redirect_uri' do
      url = service.logout_url(
        post_logout_redirect_uri: 'http://example.com/logout',
      )

      expect(url).to include("#{api_url}/realms/#{realm}/protocol/openid-connect/logout")
      expect(url).to include('post_logout_redirect_uri=http')
    end

    it 'includes client_id when provided' do
      url = service.logout_url(
        post_logout_redirect_uri: 'http://example.com/logout',
        client_id: 'test-client-123',
      )

      expect(url).to include('client_id=test-client-123')
    end

    context 'when API URL is not configured' do
      before do
        service.config[:api_url] = nil
      end

      it 'returns the redirect URI as-is' do
        url = service.logout_url(
          post_logout_redirect_uri: 'http://example.com/logout',
        )

        expect(url).to eq('http://example.com/logout')
      end
    end
  end
end
