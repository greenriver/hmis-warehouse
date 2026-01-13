###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'webmock/rspec'

RSpec.describe Idp::ZitadelService, type: :model do
  let(:api_url) { 'http://zitadel.test:8080' }
  let(:token) { 'test-token' }
  let(:org_id) { 'org-123' }
  let(:project_id) { 'proj-456' }

  let(:service) do
    described_class.new(
      config: {
        api_url: api_url,
        service_token: token,
        org_id: org_id,
        project_id: project_id,
      },
    )
  end

  before do
    WebMock.disable_net_connect!
  end

  after do
    WebMock.reset!
    WebMock.allow_net_connect!
  end

  describe '#create_user' do
    let(:user_email) { 'test@example.com' }

    context 'with valid user data' do
      before do
        stub_request(:post, "#{api_url}/management/v1/users/human").
          to_return(
            status: 200,
            body: { userId: 'user-456' }.to_json,
          )
      end

      it 'creates user and returns success with user ID' do
        result = service.create_user(
          email: user_email,
          first_name: 'John',
          last_name: 'Doe',
        )

        expect(result[:success]).to be true
        expect(result[:connector_user_id]).to eq('user-456')
      end

      it 'includes phone when provided' do
        result = service.create_user(
          email: user_email,
          first_name: 'John',
          last_name: 'Doe',
          phone: '+15551234567',
        )

        expect(result[:success]).to be true
      end
    end

    context 'with API error response' do
      before do
        stub_request(:post, "#{api_url}/management/v1/users/human").
          to_return(
            status: 400,
            body: { message: 'User already exists' }.to_json,
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

  describe '#test_connection' do
    context 'with successful connection' do
      before do
        stub_request(:get, "#{api_url}/management/v1/orgs/me").
          with(headers: { 'Authorization' => "Bearer #{token}" }).
          to_return(
            status: 200,
            body: { org: { id: org_id, name: 'Test Org' } }.to_json,
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
        stub_request(:get, "#{api_url}/management/v1/orgs/me").
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
        stub_request(:get, "#{api_url}/management/v1/orgs/me").
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
        stub_request(:get, "#{api_url}/management/v1/orgs/me").
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
        userId: user.id.to_s,
        user: hash_including(
          userName: 'test@example.com',
          profile: hash_including(
            firstName: 'John',
            lastName: 'Doe',
            displayName: 'John Doe',
            preferredLanguage: 'en',
          ),
          email: hash_including(
            email: 'test@example.com',
            isEmailVerified: true,
          ),
          phone: hash_including(
            phone: '+15551234567',
            isPhoneVerified: false,
          ),
        ),
      )
    end

    it 'excludes phone when not present' do
      user.update(phone: nil)
      result = service.build_import_user_data(user)

      expect(result[:user]).not_to have_key(:phone)
    end

    it 'marks email as unverified when confirmed_at is nil' do
      user.update(confirmed_at: nil)
      result = service.build_import_user_data(user)

      expect(result[:user][:email][:isEmailVerified]).to be false
    end

    context 'with password hash' do
      before do
        user.update(encrypted_password: '$2a$12$test_hash_value')
      end

      it 'includes hashed password with bcrypt algorithm' do
        result = service.build_import_user_data(user)

        expect(result[:user][:hashedPassword]).to match(
          value: '$2a$12$test_hash_value',
          algorithm: 'bcrypt',
        )
      end
    end

    context 'with 2FA enabled' do
      let(:otp_secret) { 'JBSWY3DPEHPK3PXP' }

      before do
        user.update(encrypted_otp_secret: 'encrypted_value')
        allow(user).to receive(:otp_secret).and_return(otp_secret)
      end

      it 'includes OTP code' do
        result = service.build_import_user_data(user)
        expect(result[:user][:otpCode]).to eq(otp_secret)
      end
    end

    context 'when OTP decryption fails' do
      before do
        user.update(encrypted_otp_secret: 'encrypted_value')
        allow(user).to receive(:otp_secret).
          and_raise(OpenSSL::Cipher.new('cip-her-err'))
        allow(Rails.logger).to receive(:warn)
      end

      it 'logs warning and excludes OTP' do
        result = service.build_import_user_data(user)

        expect(result[:user][:otpCode]).to be_nil
        expect(Rails.logger).to have_received(:warn).
          with(/Failed to decrypt OTP secret/)
      end
    end
  end

  describe '#bulk_import_users' do
    let(:users) { create_list(:user, 3, confirmed_at: 1.day.ago) }

    context 'with successful import' do
      before do
        stub_request(:post, "#{api_url}/admin/v1/import").
          to_return(
            status: 200,
            body: { status: 'completed' }.to_json,
          )
      end

      it 'returns success with imported count' do
        result = service.bulk_import_users(users)

        expect(result[:success]).to be true
        expect(result[:imported_count]).to eq(3)
        expect(result[:response]).to be_a(Hash)
      end

      it 'accepts custom timeout' do
        result = service.bulk_import_users(users, timeout: '20m')
        expect(result[:success]).to be true
      end
    end

    context 'with API error' do
      before do
        stub_request(:post, "#{api_url}/admin/v1/import").
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
        stub_request(:post, "#{api_url}/admin/v1/import").
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
        stub_request(:post, "#{api_url}/admin/v1/import").
          to_return(status: 200, body: { status: 'ok' }.to_json)
      end

      it 'imports all users in single request' do
        result = service.bulk_import_users(large_batch)

        expect(result[:success]).to be true
        expect(result[:imported_count]).to eq(100)
      end
    end
  end

  describe '#import_from_file' do
    let(:file_path) { 'tmp/test_import.json' }
    let(:import_data) do
      {
        timeout: '10m',
        data_orgs: {
          orgs: [
            {
              orgId: org_id,
              humanUsers: [
                {
                  userId: '1',
                  user: { userName: 'test1@example.com' },
                },
              ],
            },
          ],
        },
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
        stub_request(:post, "#{api_url}/admin/v1/import").
          to_return(status: 200, body: { status: 'ok' }.to_json)
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
        stub_request(:post, "#{api_url}/admin/v1/import").
          to_return(status: 400, body: { message: 'Invalid data' }.to_json)
      end

      it 'raises ServiceError with API error message' do
        expect do
          service.import_from_file(file_path)
        end.to raise_error(Idp::ServiceError)
      end
    end
  end

  describe '#export_users_to_import_format' do
    let(:users) { create_list(:user, 3, confirmed_at: 1.day.ago) }

    it 'builds correct export structure without making API call' do
      result = service.export_users_to_import_format(users)

      expect(result).to include(
        timeout: '10m',
        data_orgs: hash_including(
          orgs: array_including(
            hash_including(
              orgId: org_id,
              humanUsers: array_including(
                hash_including(userId: users.first.id.to_s),
              ),
            ),
          ),
        ),
      )
    end

    it 'does not make any HTTP requests' do
      expect(WebMock).not_to have_requested(:post, /#{api_url}/)
      service.export_users_to_import_format(users)
      expect(WebMock).not_to have_requested(:post, /#{api_url}/)
    end

    it 'handles single user' do
      user = create(:user, confirmed_at: 1.day.ago)
      result = service.export_users_to_import_format([user])

      human_users = result.dig(:data_orgs, :orgs, 0, :humanUsers)
      expect(human_users.length).to eq(1)
      expect(human_users[0][:userId]).to eq(user.id.to_s)
    end

    it 'handles empty user list' do
      result = service.export_users_to_import_format([])

      human_users = result.dig(:data_orgs, :orgs, 0, :humanUsers)
      expect(human_users).to be_empty
    end
  end

  describe '#idp_name' do
    it 'returns Zitadel' do
      expect(service.idp_name).to eq('Zitadel')
    end
  end

  describe '#supports_user_management?' do
    context 'when API URL and token are configured' do
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

    context 'when token is missing' do
      before do
        service.config[:service_token] = nil
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

      expect(url).to include("#{api_url}/oidc/v1/end_session")
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
