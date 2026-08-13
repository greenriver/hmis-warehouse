###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

RSpec.describe Idp::ServiceConfig, :jwt_only, type: :model do
  describe 'validations' do
    subject { build(:idp_service_config) }

    it { is_expected.to validate_presence_of(:provider) }
    it { is_expected.to validate_presence_of(:connector_id) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:api_url) }
    it { is_expected.to validate_presence_of(:service_token) }

    describe 'provider validation' do
      it 'rejects an unregistered provider' do
        config = build(:idp_service_config, provider: 'unknown_provider')
        expect(config).not_to be_valid
        expect(config.errors[:provider].first).to include('unknown provider')
      end

      it 'accepts a free-form connector_id (the auth-proxy routing key)' do
        config = build(:idp_service_config, provider: 'keycloak', connector_id: 'keycloak-staff')
        expect(config).to be_valid
      end
    end

    describe 'keycloak build-key validation' do
      it 'rejects an active keycloak config with a blank client_id' do
        config = build(:idp_service_config, active: true, client_id: nil)
        expect(config).not_to be_valid
        expect(config.errors[:client_id]).to be_present
      end

      it 'rejects an active keycloak config with a blank keycloak_realm' do
        config = build(:idp_service_config, active: true, keycloak_realm: nil)
        expect(config).not_to be_valid
        expect(config.errors[:keycloak_realm]).to be_present
      end

      it 'allows an inactive keycloak config with a blank client_id (draft parking)' do
        config = build(:idp_service_config, active: false, client_id: nil)
        expect(config).to be_valid
      end

      it 'allows an inactive keycloak config with a blank keycloak_realm (draft parking)' do
        config = build(:idp_service_config, active: false, keycloak_realm: nil)
        expect(config).to be_valid
      end
    end

    describe 'connector_id uniqueness' do
      let!(:existing) { create(:idp_service_config, connector_id: 'keycloak') }

      it 'prevents duplicate connector_id when both active' do
        config = build(:idp_service_config, connector_id: 'keycloak')
        expect(config).not_to be_valid
        expect(config.errors[:connector_id]).to be_present
      end

      it 'allows duplicate connector_id when one is soft-deleted' do
        existing.destroy
        config = build(:idp_service_config, connector_id: 'keycloak')
        expect(config).to be_valid
      end
    end
  end

  describe 'encryption' do
    it 'encrypts service_token on create' do
      config = create(
        :idp_service_config,
        service_token: 'my-secret-token',
      )

      expect(config.encrypted_service_token).to be_present
      expect(config.encrypted_service_token).not_to eq('my-secret-token')
    end

    it 'decrypts service_token when read' do
      config = create(
        :idp_service_config,
        service_token: 'my-secret-token',
      )

      expect(config.service_token).to eq('my-secret-token')
    end

    it 'handles decryption of stored token' do
      config = create(
        :idp_service_config,
        service_token: 'original-token',
      )

      reloaded = Idp::ServiceConfig.find(config.id)
      expect(reloaded.service_token).to eq('original-token')
    end
  end

  describe '#service_class' do
    it 'returns KeycloakService class for the keycloak provider' do
      config = create(:idp_service_config, provider: 'keycloak')
      expect(config.service_class).to eq(Idp::KeycloakService)
    end

    it 'raises ServiceError for an unregistered provider' do
      config = build(:idp_service_config, provider: 'unknown_idp')
      expect { config.service_class }.to raise_error(Idp::ServiceError, /Unknown provider/)
    end
  end

  describe '#to_service' do
    it 'instantiates KeycloakService with config values' do
      config = create(
        :idp_service_config,
        connector_id: 'keycloak',
        api_url: 'http://test.keycloak:8080',
        service_token: 'test-token',
        client_id: 'my-service-account',
        keycloak_realm: 'test-realm',
      )

      service = config.to_service
      expect(service).to be_a(Idp::KeycloakService)
      expect(service.send(:api_url)).to eq('http://test.keycloak:8080')
      expect(service.send(:client_secret)).to eq('test-token')
      expect(service.send(:client_id)).to eq('my-service-account')
      expect(service.send(:realm)).to eq('test-realm')
    end

    it 'defaults to a manageable service' do
      config = create(:idp_service_config, connector_id: 'keycloak')

      expect(config.manage_users).to be true
      expect(config.to_service.supports_user_management?).to be true
    end

    it 'builds an authenticate-only service when manage_users is false' do
      config = create(:idp_service_config, connector_id: 'keycloak', manage_users: false)

      service = config.to_service
      expect(service).to be_a(Idp::KeycloakService)
      expect(service.supports_user_management?).to be false
    end

    it 'carries the per-realm browser fields into the service (DB, not ENV)' do
      config = create(
        :idp_service_config,
        connector_id: 'keycloak',
        browser_url: 'https://kc.public.test',
        account_client_id: 'my-account',
      )

      service = config.to_service
      expect(service.account_console_url).to eq('https://kc.public.test/realms/openpath/account')
      expect(service.send(:account_client_id)).to eq('my-account')
    end

    it 'raises ServiceError for an unregistered provider' do
      config = build(:idp_service_config, provider: 'unknown')
      expect { config.to_service }.to raise_error(Idp::ServiceError, /Unknown provider/)
    end
  end

  describe 'scopes' do
    describe '.active' do
      let!(:active_config) { create(:idp_service_config, active: true) }
      let!(:inactive_config) { create(:idp_service_config, active: false) }

      it 'returns only active configs' do
        expect(described_class.active).to include(active_config)
        expect(described_class.active).not_to include(inactive_config)
      end
    end
  end

  describe 'soft delete' do
    let(:config) { create(:idp_service_config) }

    it 'soft deletes the config' do
      expect(config.deleted_at).to be_nil
      config.delete
      expect(config.deleted_at).to be_present
    end

    it 'excludes soft-deleted configs from default scope' do
      config
      config.delete

      expect(described_class.find_by(id: config.id)).to be_nil
    end

    it 'allows undeleting a config' do
      config.delete
      config.restore

      expect(config.deleted_at).to be_nil
      expect(described_class.find(config.id)).to eq(config)
    end
  end

  describe '.bootstrap_from_env' do
    let(:keycloak_env) do
      {
        'KEYCLOAK_API_URL' => 'http://seed.keycloak:8080',
        'KEYCLOAK_REALM' => 'seed-realm',
        'KEYCLOAK_SERVICE_CLIENT_ID' => 'seed-client',
        'KEYCLOAK_SERVICE_CLIENT_SECRET' => 'seed-secret',
        'KEYCLOAK_PUBLIC_URL' => 'https://seed.public.test',
        'KEYCLOAK_ACCOUNT_CLIENT_ID' => 'seed-account',
      }
    end

    # Stub only the KEYCLOAK_* keys we read; everything else passes through.
    def stub_env(values)
      allow(ENV).to receive(:[]).and_call_original
      keycloak_env.each_key do |key|
        allow(ENV).to receive(:[]).with(key).and_return(values[key])
      end
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('KEYCLOAK_CONNECTOR_ID', 'keycloak').
        and_return(values.fetch('KEYCLOAK_CONNECTOR_ID', 'keycloak'))
    end

    context 'in JWT mode with core KEYCLOAK_* env present' do
      before do
        allow(AuthMethod).to receive(:jwt?).and_return(true)
        stub_env(keycloak_env)
      end

      it 'creates one active Idp::ServiceConfig from ENV' do
        expect { described_class.bootstrap_from_env }.to change(described_class, :count).by(1)

        config = described_class.find_by(connector_id: 'keycloak')
        expect(config).to have_attributes(
          provider: 'keycloak',
          connector_id: 'keycloak',
          name: 'Keycloak (seeded from ENV)',
          api_url: 'http://seed.keycloak:8080',
          keycloak_realm: 'seed-realm',
          client_id: 'seed-client',
          browser_url: 'https://seed.public.test',
          account_client_id: 'seed-account',
          manage_users: true,
          active: true,
        )
        expect(config.service_token).to eq('seed-secret')
      end

      it 'uses KEYCLOAK_CONNECTOR_ID as the connector_id when set' do
        stub_env(keycloak_env.merge('KEYCLOAK_CONNECTOR_ID' => 'realm-a'))

        described_class.bootstrap_from_env

        expect(described_class.find_by(connector_id: 'realm-a')).to be_present
      end
    end

    context 'when not in JWT mode' do
      before do
        allow(AuthMethod).to receive(:jwt?).and_return(false)
        stub_env(keycloak_env)
      end

      it 'is a no-op' do
        expect { described_class.bootstrap_from_env }.not_to change(described_class, :count)
      end
    end

    context 'when core KEYCLOAK_* env is absent (external IdP)' do
      before do
        allow(AuthMethod).to receive(:jwt?).and_return(true)
        stub_env({}) # every KEYCLOAK_* key nil
      end

      it 'is a silent no-op and does not raise' do
        expect { described_class.bootstrap_from_env }.not_to change(described_class, :count)
      end
    end

    context 'with a partial KEYCLOAK_* env (a core build key absent)' do
      before do
        allow(AuthMethod).to receive(:jwt?).and_return(true)
      end

      it 'is a silent no-op when KEYCLOAK_REALM is absent' do
        stub_env(keycloak_env.merge('KEYCLOAK_REALM' => nil))

        expect { described_class.bootstrap_from_env }.not_to change(described_class, :count)
      end

      it 'is a silent no-op when KEYCLOAK_SERVICE_CLIENT_ID is absent' do
        stub_env(keycloak_env.merge('KEYCLOAK_SERVICE_CLIENT_ID' => nil))

        expect { described_class.bootstrap_from_env }.not_to change(described_class, :count)
      end
    end

    context 're-seeding (runs on every deploy)' do
      before do
        allow(AuthMethod).to receive(:jwt?).and_return(true)
        stub_env(keycloak_env)
      end

      it 'does not create a second row or clobber a UI credential edit' do
        described_class.bootstrap_from_env
        existing = described_class.find_by(connector_id: 'keycloak')
        existing.update!(api_url: 'http://ui-edited.keycloak:8080')

        expect { described_class.bootstrap_from_env }.not_to change(described_class, :count)
        expect(existing.reload.api_url).to eq('http://ui-edited.keycloak:8080')
      end

      it 'does not resurrect a soft-deleted row' do
        described_class.bootstrap_from_env
        described_class.find_by(connector_id: 'keycloak').destroy

        expect { described_class.bootstrap_from_env }.not_to change(described_class, :count)
        expect(described_class.find_by(connector_id: 'keycloak')).to be_nil
        expect(described_class.with_deleted.find_by(connector_id: 'keycloak')).to be_present
      end

      it 'does not reactivate a deactivated (active: false) row' do
        described_class.bootstrap_from_env
        described_class.find_by(connector_id: 'keycloak').update!(active: false)

        expect { described_class.bootstrap_from_env }.not_to change(described_class, :count)
        expect(described_class.find_by(connector_id: 'keycloak').active).to be(false)
      end
    end
  end
end
