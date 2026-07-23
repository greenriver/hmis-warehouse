###
# Copyright Green River Data Group, Inc.
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

    context 'with a 201 response missing the Location header' do
      before do
        stub_request(:post, "#{api_url}/admin/realms/#{realm}/users").
          to_return(status: 201)
      end

      it 'returns success with a nil connector_user_id rather than raising' do
        result = service.create_user(
          email: user_email,
          first_name: 'John',
          last_name: 'Doe',
        )

        expect(result[:success]).to be true
        expect(result[:connector_user_id]).to be_nil
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
        end.to raise_error(Idp::ServiceError, /Failed to create user: User exists with same username/)
      end
    end
  end

  describe '#find_user_by_email' do
    let(:email) { 'jane@example.com' }
    let(:search_url) { "#{api_url}/admin/realms/#{realm}/users" }

    it 'queries by exact email and returns the matching representation' do
      stub_request(:get, search_url).
        with(query: { email: email, exact: 'true' }).
        to_return(status: 200, body: [{ id: 'kc-1', email: email }].to_json)

      result = service.find_user_by_email(email: email)

      expect(result['id']).to eq('kc-1')
    end

    it 'returns nil when no user matches' do
      stub_request(:get, search_url).
        with(query: { email: email, exact: 'true' }).
        to_return(status: 200, body: [].to_json)

      expect(service.find_user_by_email(email: email)).to be_nil
    end
  end

  describe '#send_execute_actions_email' do
    let(:user_id) { 'kc-user-id' }
    let(:actions_url) { "#{api_url}/admin/realms/#{realm}/users/#{user_id}/execute-actions-email" }

    it 'PUTs the required actions and returns true on 204' do
      stub_request(:put, actions_url).to_return(status: 204)

      result = service.send_execute_actions_email(user_id: user_id, actions: ['UPDATE_PASSWORD', 'VERIFY_EMAIL'])

      expect(result).to be true
      expect(
        a_request(:put, actions_url).with(body: ['UPDATE_PASSWORD', 'VERIFY_EMAIL'].to_json),
      ).to have_been_made
    end

    it 'raises a delivery-focused ServiceError, not a raw status code, when Keycloak fails to send (e.g. bad address or SMTP not configured)' do
      stub_request(:put, actions_url).to_return(status: 500, body: { errorMessage: 'Failed to send email' }.to_json)

      expect do
        service.send_execute_actions_email(user_id: user_id, actions: ['UPDATE_PASSWORD'])
      end.to raise_error(Idp::ServiceError, /couldn't deliver it.*email address is valid/)
    end
  end

  describe '#update_user' do
    let(:user_id) { 'keycloak-user-id' }
    let(:current_representation) do
      { id: user_id, username: 'jane', firstName: 'Old', lastName: 'Name', email: 'old@example.com' }
    end

    context 'with successful update' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(status: 200, body: current_representation.to_json)
        stub_request(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(status: 204)
      end

      it 'returns true and sends the full representation with the mapped attribute merged in' do
        result = service.update_user(
          user_id: user_id,
          attributes: { first_name: 'Jane' },
        )

        expect(result).to be true
        expect(
          a_request(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
            with(body: current_representation.merge(firstName: 'Jane')),
        ).to have_been_made
      end

      it 'sets emailVerified to false and syncs username when the email changes, without clearing other fields' do
        actions_url = "#{api_url}/admin/realms/#{realm}/users/#{user_id}/execute-actions-email"
        stub_request(:put, actions_url).to_return(status: 204)

        service.update_user(
          user_id: user_id,
          attributes: { email: 'new@example.com' },
        )

        expect(
          a_request(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
            with(body: current_representation.merge(email: 'new@example.com', username: 'new@example.com', emailVerified: false)),
        ).to have_been_made
      end

      it 'sends a verification email when the email changes' do
        actions_url = "#{api_url}/admin/realms/#{realm}/users/#{user_id}/execute-actions-email"
        stub_request(:put, actions_url).to_return(status: 204)

        service.update_user(
          user_id: user_id,
          attributes: { email: 'new@example.com' },
        )

        expect(
          a_request(:put, actions_url).with(body: ['VERIFY_EMAIL'].to_json),
        ).to have_been_made
      end

      it 'does not send a verification email or touch username when email is unchanged' do
        service.update_user(
          user_id: user_id,
          attributes: { first_name: 'Jane' },
        )

        expect(WebMock).not_to have_requested(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}/execute-actions-email")
      end

      it 'carries fields the patch never references (custom attributes, requiredActions) through the merge' do
        full_representation = current_representation.merge(
          attributes: { department: ['Housing'] },
          requiredActions: ['CONFIGURE_TOTP'],
        )
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(status: 200, body: full_representation.to_json)

        service.update_user(user_id: user_id, attributes: { first_name: 'Jane' })

        expect(
          a_request(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
            with(body: full_representation.merge(firstName: 'Jane')),
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
        expect(WebMock).not_to have_requested(:get, /#{Regexp.escape(api_url)}/)
        expect(WebMock).not_to have_requested(:put, /#{Regexp.escape(api_url)}/)
      end
    end

    context 'with API error' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(status: 200, body: current_representation.to_json)
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
        end.to raise_error(Idp::ServiceError, /Failed to update user: Invalid attribute/)
      end
    end

    context 'when the user cannot be fetched first' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(status: 404)
      end

      it 'raises ServiceError from the GET instead of PUTting a partial body' do
        expect do
          service.update_user(user_id: user_id, attributes: { first_name: 'Jane' })
        end.to raise_error(Idp::ServiceError, /User not found/)
        expect(WebMock).not_to have_requested(:put, /#{Regexp.escape(api_url)}/)
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
        end.to raise_error(Idp::ServiceError, /User not found: #{user_id}/)
      end
    end
  end

  describe '#reactivate_user' do
    let(:user_id) { 'keycloak-user-id' }
    let(:current_representation) { { id: user_id, username: 'test@example.com', firstName: 'Jane' } }

    context 'with successful reactivation' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(status: 200, body: current_representation.to_json)
        stub_request(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(status: 204)
      end

      it 'returns true and enables the user without clearing other fields' do
        result = service.reactivate_user(user_id: user_id)

        expect(result).to be true
        expect(
          a_request(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
            with(body: current_representation.merge(enabled: true)),
        ).to have_been_made
      end
    end

    context 'with API error' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(status: 200, body: current_representation.to_json)
        stub_request(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(
            status: 404,
            body: { error: 'User not found' }.to_json,
          )
      end

      it 'raises ServiceError' do
        expect do
          service.reactivate_user(user_id: user_id)
        end.to raise_error(Idp::ServiceError, /Failed to reactivate user: User not found/)
      end
    end
  end

  describe '#deactivate_user' do
    let(:user_id) { 'keycloak-user-id' }
    let(:current_representation) { { id: user_id, username: 'test@example.com', firstName: 'Jane' } }

    context 'with successful deactivation' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(status: 200, body: current_representation.to_json)
        stub_request(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(status: 204)
      end

      it 'returns true and disables the user without clearing other fields' do
        result = service.deactivate_user(user_id: user_id)

        expect(result).to be true
        expect(
          a_request(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
            with(body: current_representation.merge(enabled: false)),
        ).to have_been_made
      end
    end

    context 'with API error' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(status: 200, body: current_representation.to_json)
        stub_request(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(
            status: 404,
            body: { error: 'User not found' }.to_json,
          )
      end

      it 'raises ServiceError' do
        expect do
          service.deactivate_user(user_id: user_id)
        end.to raise_error(Idp::ServiceError, /Failed to deactivate user: User not found/)
      end
    end
  end

  describe '#set_required_action' do
    let(:user_id) { 'keycloak-user-id' }
    let(:current_representation) { { id: user_id, username: 'test@example.com', firstName: 'Jane' } }

    context 'with a successful update' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(status: 200, body: current_representation.to_json)
        stub_request(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(status: 204)
      end

      it 'returns true and sets the required actions without clearing other fields' do
        result = service.set_required_action(user_id: user_id, actions: ['UPDATE_PASSWORD'])

        expect(result).to be true
        expect(
          a_request(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
            with(body: current_representation.merge(requiredActions: ['UPDATE_PASSWORD'])),
        ).to have_been_made
      end
    end

    context 'with API error' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(status: 200, body: current_representation.to_json)
        stub_request(:put, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
          to_return(
            status: 404,
            body: { error: 'User not found' }.to_json,
          )
      end

      it 'raises ServiceError' do
        expect do
          service.set_required_action(user_id: user_id, actions: ['UPDATE_PASSWORD'])
        end.to raise_error(Idp::ServiceError, /Failed to set required actions: User not found/)
      end
    end
  end

  describe '#test_connection' do
    context 'with successful connection' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users?max=1").
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
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users?max=1").
          to_return(status: 401)
      end

      it 'returns failure with auth message' do
        result = service.test_connection

        expect(result[:success]).to be false
        expect(result[:message]).to include('Authentication failed')
      end
    end

    context 'with endpoint not found' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users?max=1").
          to_return(status: 404)
      end

      it 'returns failure with an endpoint-not-found message' do
        result = service.test_connection

        expect(result[:success]).to be false
        expect(result[:message]).to include('API endpoint not found')
      end
    end

    context 'with a Keycloak server error' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users?max=1").
          to_return(status: 500)
      end

      it 'returns failure with the server error message' do
        result = service.test_connection

        expect(result[:success]).to be false
        expect(result[:message]).to include('Keycloak server error: 500')
      end
    end

    context 'with connection refused' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users?max=1").
          to_raise(Errno::ECONNREFUSED)
      end

      it 'returns failure with connection message' do
        result = service.test_connection

        expect(result[:success]).to be false
        expect(result[:message]).to include('Connection refused')
      end
    end

    context 'with host unreachable' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users?max=1").
          to_raise(Errno::EHOSTUNREACH)
      end

      it 'returns failure with a host-unreachable message' do
        result = service.test_connection

        expect(result[:success]).to be false
        expect(result[:message]).to include('Host unreachable')
      end
    end

    context 'with timeout' do
      before do
        stub_request(:get, "#{api_url}/admin/realms/#{realm}/users?max=1").
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

  describe 'token caching' do
    let(:user_id) { 'keycloak-user-id' }

    before do
      stub_request(:get, "#{api_url}/admin/realms/#{realm}/users/#{user_id}").
        to_return(status: 200, body: { id: user_id, username: 'test@example.com' }.to_json)
    end

    it 'reuses the cached token across requests instead of fetching a new one each time' do
      service.get_user(user_id: user_id)
      service.get_user(user_id: user_id)

      expect(a_request(:post, token_url)).to have_been_made.once
    end

    it 'fetches a new token once the cached one has expired' do
      service.get_user(user_id: user_id)

      travel(6.minutes) do
        service.get_user(user_id: user_id)
      end

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

  describe '#supports_account_backfill?' do
    it 'returns true (the backfill runs against Keycloak)' do
      expect(service.supports_account_backfill?).to be true
    end

    it 'defaults to false on a service without a manageable admin API' do
      expect(Idp::NullService.new('keycloak').supports_account_backfill?).to be false
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

  describe '#each_user' do
    let(:users_url) { "#{api_url}/admin/realms/#{realm}/users" }

    def stub_page(first, max, users)
      stub_request(:get, users_url).
        with(query: { first: first.to_s, max: max.to_s }).
        to_return(
          status: 200,
          body: users.to_json,
          headers: { 'Content-Type' => 'application/json' },
        )
    end

    it 'pages past the first full page and stops on the final short page' do
      page1 = Array.new(2) { |i| { 'id' => "id-#{i}", 'email' => "u#{i}@example.com" } }
      page2 = [{ 'id' => 'id-2', 'email' => 'u2@example.com' }]
      stub_page(0, 2, page1)
      stub_page(2, 2, page2)

      collected = service.each_user(page_size: 2).to_a

      expect(collected).to eq(
        [
          { email: 'u0@example.com', id: 'id-0' },
          { email: 'u1@example.com', id: 'id-1' },
          { email: 'u2@example.com', id: 'id-2' },
        ],
      )
    end

    it 'stops when a full page is followed by an empty page' do
      stub_page(0, 2, [{ 'id' => 'a', 'email' => 'a@x.com' }, { 'id' => 'b', 'email' => 'b@x.com' }])
      stub_page(2, 2, [])

      expect(service.each_user(page_size: 2).to_a.size).to eq(2)
    end
  end
end
