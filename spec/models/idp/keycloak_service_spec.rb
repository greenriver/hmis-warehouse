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

      it 'does not raise an error' do
        expect do
          service.update_user(
            user_id: user_id,
            attributes: { first_name: 'Jane' },
          )
        end.not_to raise_error
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

      it 'returns true' do
        result = service.reactivate_user(user_id: user_id)

        expect(result).to be true
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

  describe '#build_import_user_data' do
    let(:user) do
      create(
        :user,
        email: 'test@example.com',
        first_name: 'John',
        last_name: 'Doe',
        phone: '+15551234567',
        confirmed_at: 1.day.ago,
      )
    end

    it 'builds correct import structure with basic fields' do
      result = service.build_import_user_data(user)

      expect(result).to match(
        hash_including(
          username: 'test@example.com',
          email: 'test@example.com',
          firstName: 'John',
          lastName: 'Doe',
          enabled: true,
          emailVerified: true,
        ),
      )
      expect(result).not_to have_key(:id)
    end

    it 'does not include phone field' do
      result = service.build_import_user_data(user)

      expect(result).not_to have_key(:phone)
    end

    it 'includes warehouse group when user has warehouse access' do
      allow(user).to receive(:login_to?).with(:warehouse).and_return(true)
      allow(user).to receive(:login_to?).with(:hmis).and_return(false)
      result = service.build_import_user_data(user)

      expect(result[:groups]).to include('/warehouse-users')
      expect(result[:groups]).not_to include('/hmis-users')
    end

    it 'includes hmis group when user has hmis access' do
      allow(user).to receive(:login_to?).with(:warehouse).and_return(false)
      allow(user).to receive(:login_to?).with(:hmis).and_return(true)
      result = service.build_import_user_data(user)

      expect(result[:groups]).to include('/hmis-users')
      expect(result[:groups]).not_to include('/warehouse-users')
    end

    it 'marks email as unverified when confirmed_at is nil' do
      user.update(confirmed_at: nil)
      result = service.build_import_user_data(user)

      expect(result[:emailVerified]).to be false
    end

    context 'with password hash' do
      before do
        user.update(encrypted_password: '$2a$12$test_hash_value')
      end

      it 'includes hashed password as bcrypt credential' do
        result = service.build_import_user_data(user)

        password_cred = result[:credentials].find { |c| c[:type] == 'password' }
        expect(password_cred).to be_present
        secret_data = JSON.parse(password_cred[:secretData])
        expect(secret_data['value']).to eq('$2a$12$test_hash_value')
        cred_data = JSON.parse(password_cred[:credentialData])
        expect(cred_data['algorithm']).to eq('bcrypt')
      end
    end

    context 'with 2FA enabled' do
      let(:otp_secret) { 'JBSWY3DPEHPK3PXP' }

      before do
        user.update(encrypted_otp_secret: 'encrypted_value', otp_required_for_login: true)
        allow(user).to receive(:otp_secret).and_return(otp_secret)
      end

      it 'includes OTP credential with correct type and format' do
        result = service.build_import_user_data(user)

        otp_cred = result[:credentials].find { |c| c[:type] == 'otp' }
        expect(otp_cred).to be_present
        secret_data = JSON.parse(otp_cred[:secretData])
        expect(secret_data['value']).to eq(otp_secret)
        expect(secret_data.keys).to eq(['value'])
        cred_data = JSON.parse(otp_cred[:credentialData])
        expect(cred_data['subType']).to eq('totp')
        expect(cred_data['digits']).to eq(6)
        expect(cred_data['period']).to eq(30)
        expect(cred_data['algorithm']).to eq('HmacSHA1')
        # secretEncoding: BASE32 tells Keycloak to Base32-decode the value before use as HMAC key
        expect(cred_data['secretEncoding']).to eq('BASE32')
      end
    end

    context 'when OTP decryption fails' do
      before do
        user.update(encrypted_otp_secret: 'encrypted_value', otp_required_for_login: true)
        allow(user).to receive(:otp_secret).
          and_raise(OpenSSL::Cipher::CipherError, 'unsupported cipher algorithm')
        allow(Rails.logger).to receive(:warn)
      end

      it 'logs warning and excludes OTP credential' do
        result = service.build_import_user_data(user)

        otp_cred = result[:credentials].find { |c| c[:type] == 'otp' }
        expect(otp_cred).to be_nil
        expect(Rails.logger).to have_received(:warn).
          with(/Failed to decrypt OTP secret/)
      end
    end
  end

  describe '#bulk_import_users' do
    let(:users) { create_list(:user, 3, confirmed_at: 1.day.ago) }

    context 'with successful import' do
      before do
        stub_request(:post, "#{api_url}/admin/realms/#{realm}/partialImport").
          to_return(
            status: 200,
            body: { overwritten: 0, added: 3, skipped: 0 }.to_json,
          )
      end

      it 'returns success with imported count' do
        result = service.bulk_import_users(users)

        expect(result[:success]).to be true
        expect(result[:imported_count]).to eq(3)
        expect(result[:response]).to be_a(Hash)
      end
    end

    context 'with API error' do
      before do
        stub_request(:post, "#{api_url}/admin/realms/#{realm}/partialImport").
          to_return(
            status: 500,
            body: { error: 'Internal server error' }.to_json,
          )
      end

      it 'returns failure result with error message' do
        result = service.bulk_import_users(users)

        expect(result[:success]).to be false
        expect(result[:error]).to include('500')
        expect(result[:failed_count]).to eq(3)
      end
    end

    context 'with network timeout' do
      before do
        stub_request(:post, "#{api_url}/admin/realms/#{realm}/partialImport").
          to_timeout
      end

      it 'handles timeout gracefully' do
        result = service.bulk_import_users(users)

        expect(result[:success]).to be false
        expect(result[:error]).to be_present
        expect(result[:failed_count]).to eq(3)
      end
    end

    context 'with large batch' do
      let(:large_batch) { create_list(:user, 100, confirmed_at: 1.day.ago) }

      before do
        stub_request(:post, "#{api_url}/admin/realms/#{realm}/partialImport").
          to_return(status: 200, body: { overwritten: 0, added: 100, skipped: 0 }.to_json)
      end

      it 'imports all users in single request' do
        result = service.bulk_import_users(large_batch)

        expect(result[:success]).to be true
        expect(result[:imported_count]).to eq(100)
      end
    end
  end

  describe '#export_users_to_import_format' do
    let(:users) { create_list(:user, 3, confirmed_at: 1.day.ago) }

    it 'builds correct export structure without making API call' do
      result = service.export_users_to_import_format(users)

      expect(result).to include(
        ifResourceExists: 'SKIP',
        users: array_including(
          hash_including(username: users.first.email),
        ),
      )
    end

    it 'does not make any HTTP requests' do
      expect(WebMock).not_to have_requested(:post, /#{Regexp.escape(api_url)}/)
      service.export_users_to_import_format(users)
      expect(WebMock).not_to have_requested(:post, /#{Regexp.escape(api_url)}/)
    end

    it 'handles single user' do
      user = create(:user, confirmed_at: 1.day.ago)
      result = service.export_users_to_import_format([user])

      expect(result[:users].length).to eq(1)
      expect(result[:users].first[:username]).to eq(user.email)
    end

    it 'handles empty user list' do
      result = service.export_users_to_import_format([])

      expect(result[:users]).to be_empty
    end
  end

  describe '#import_from_file' do
    let(:file_path) { 'tmp/test_keycloak_import.json' }
    let(:import_data) do
      {
        ifResourceExists: 'SKIP',
        users: [
          { id: '1', username: 'test1@example.com' },
        ],
      }
    end

    before do
      File.write(file_path, JSON.generate(import_data))
    end

    after do
      File.delete(file_path) if File.exist?(file_path)
    end

    context 'with valid file' do
      before do
        stub_request(:post, "#{api_url}/admin/realms/#{realm}/partialImport").
          to_return(status: 200, body: { added: 1, skipped: 0 }.to_json)
      end

      it 'reads file and imports users' do
        result = service.import_from_file(file_path)

        expect(result[:success]).to be true
        expect(result[:response]).to be_a(Hash)
      end
    end

    context 'with missing file' do
      it 'raises ServiceError' do
        expect do
          service.import_from_file('nonexistent.json')
        end.to raise_error(Idp::ServiceError)
      end
    end

    context 'with API error' do
      before do
        stub_request(:post, "#{api_url}/admin/realms/#{realm}/partialImport").
          to_return(status: 400, body: { error: 'Invalid data' }.to_json)
      end

      it 'raises ServiceError with API error message' do
        expect do
          service.import_from_file(file_path)
        end.to raise_error(Idp::ServiceError)
      end
    end
  end

  describe '#idp_name' do
    it 'returns Keycloak' do
      expect(service.idp_name).to eq('Keycloak')
    end
  end

  describe '#supports_user_management?' do
    context 'when API URL and credentials are configured' do
      it 'returns true' do
        expect(service.supports_user_management?).to be true
      end
    end

    context 'when API URL is missing' do
      before do
        service.config[:api_url] = nil
      end

      it 'returns false' do
        expect(service.supports_user_management?).to be false
      end
    end

    context 'when client_id is missing' do
      before do
        service.config[:client_id] = nil
      end

      it 'returns false' do
        expect(service.supports_user_management?).to be false
      end
    end

    context 'when client_secret is missing' do
      before do
        service.config[:client_secret] = nil
      end

      it 'returns false' do
        expect(service.supports_user_management?).to be false
      end
    end
  end

  describe '#supports_profile_updates?' do
    it 'returns true' do
      expect(service.supports_profile_updates?).to be true
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
