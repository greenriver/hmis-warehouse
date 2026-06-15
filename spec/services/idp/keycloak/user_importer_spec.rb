###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'webmock/rspec'

RSpec.describe Idp::Keycloak::UserImporter, type: :model do
  let(:api_url) { 'http://keycloak.test:8080' }
  let(:realm) { 'openpath' }
  let(:client_id) { 'rails-service-account' }
  let(:client_secret) { 'test-secret' }
  let(:token_url) { "#{api_url}/realms/#{realm}/protocol/openid-connect/token" }

  let(:service) do
    Idp::KeycloakService.new(
      config: {
        api_url: api_url,
        realm: realm,
        client_id: client_id,
        client_secret: client_secret,
      },
    )
  end

  let(:importer) { described_class.new(service: service) }

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

  describe '.migration_scope' do
    let!(:confirmed_active) { create(:user, confirmed_at: 1.day.ago, active: true) }
    let!(:inactive) { create(:user, confirmed_at: 1.day.ago, active: false) }
    let!(:invited_not_accepted) do
      create(:user, confirmed_at: nil, invitation_accepted_at: nil, active: true)
    end

    it 'includes confirmed, active users' do
      expect(described_class.migration_scope(since: nil)).to include(confirmed_active)
    end

    it 'excludes inactive users' do
      expect(described_class.migration_scope(since: nil)).not_to include(inactive)
    end

    it 'excludes invited-but-not-accepted users (confirmed_at is nil)' do
      expect(described_class.migration_scope(since: nil)).not_to include(invited_not_accepted)
    end

    it 'with since: nil returns the full base population' do
      old_user = create(:user, confirmed_at: 1.day.ago, active: true, updated_at: 1.year.ago)

      expect(described_class.migration_scope(since: nil)).to include(confirmed_active, old_user)
    end

    it 'with a since value excludes users whose updated_at is older' do
      old_user = create(:user, confirmed_at: 1.day.ago, active: true, updated_at: 10.days.ago)
      recent_user = create(:user, confirmed_at: 1.day.ago, active: true, updated_at: 1.hour.ago)

      scope = described_class.migration_scope(since: 1.day.ago)

      expect(scope).to include(recent_user)
      expect(scope).not_to include(old_user)
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
      result = importer.build_import_user_data(user)

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
      result = importer.build_import_user_data(user)

      expect(result).not_to have_key(:phone)
    end

    it 'includes warehouse group for a role-based user without ACLs' do
      result = importer.build_import_user_data(user)

      expect(result[:groups]).to include('/warehouse-users')
      expect(result[:groups]).not_to include('/hmis-users')
    end

    it 'includes hmis group when user is in an HMIS UserGroup' do
      hmis_user_group = create(:hmis_user_group)
      hmis_user_group.add(user)
      result = importer.build_import_user_data(user)

      expect(result[:groups]).to include('/hmis-users')
    end

    it 'excludes warehouse group for an ACL user with no warehouse UserGroup membership' do
      acl_user = create(:acl_user)
      result = importer.build_import_user_data(acl_user)

      expect(result[:groups]).not_to include('/warehouse-users')
    end

    it 'returns no groups for a system user' do
      system_user = User.setup_system_user
      result = importer.build_import_user_data(system_user)

      expect(result[:groups]).to be_empty
    end

    it 'marks email as unverified when confirmed_at is nil' do
      user.update(confirmed_at: nil)
      result = importer.build_import_user_data(user)

      expect(result[:emailVerified]).to be false
    end

    context 'with password hash' do
      before do
        user.update(encrypted_password: '$2a$12$test_hash_value')
      end

      it 'includes hashed password as bcrypt credential' do
        result = importer.build_import_user_data(user)

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
        result = importer.build_import_user_data(user)

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

      it 'does not migrate otp_backup_codes (intentionally dropped — see Task 4)' do
        user.update(otp_backup_codes: ['code1', 'code2', 'code3'])
        result = importer.build_import_user_data(user)

        serialized = result[:credentials].map { |c| c.values.join }.join
        expect(serialized).not_to include('code1')
        expect(result.to_json).not_to include('backup')
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
        result = importer.build_import_user_data(user)

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
        result = importer.bulk_import_users(users)

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
        result = importer.bulk_import_users(users)

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
        result = importer.bulk_import_users(users)

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
        result = importer.bulk_import_users(large_batch)

        expect(result[:success]).to be true
        expect(result[:imported_count]).to eq(100)
      end
    end
  end

  describe '#export_users_to_import_format' do
    let(:users) { create_list(:user, 3, confirmed_at: 1.day.ago) }

    it 'builds correct export structure without making API call' do
      result = importer.export_users_to_import_format(users)

      expect(result).to include(
        ifResourceExists: 'SKIP',
        users: array_including(
          hash_including(username: users.first.email),
        ),
      )
    end

    it 'does not make any HTTP requests' do
      expect(WebMock).not_to have_requested(:post, /#{Regexp.escape(api_url)}/)
      importer.export_users_to_import_format(users)
      expect(WebMock).not_to have_requested(:post, /#{Regexp.escape(api_url)}/)
    end

    it 'handles single user' do
      user = create(:user, confirmed_at: 1.day.ago)
      result = importer.export_users_to_import_format([user])

      expect(result[:users].length).to eq(1)
      expect(result[:users].first[:username]).to eq(user.email)
    end

    it 'handles empty user list' do
      result = importer.export_users_to_import_format([])

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
        result = importer.import_from_file(file_path)

        expect(result[:success]).to be true
        expect(result[:response]).to be_a(Hash)
      end
    end

    context 'with missing file' do
      it 'raises ServiceError' do
        expect do
          importer.import_from_file('nonexistent.json')
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
          importer.import_from_file(file_path)
        end.to raise_error(Idp::ServiceError)
      end
    end
  end
end
