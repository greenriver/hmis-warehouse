###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

RSpec.describe Idp::ServiceFactory, type: :model do
  describe '.for_connector' do
    context 'with database config present' do
      let!(:config) do
        create(
          :idp_service_config,
          connector_id: 'keycloak',
          api_url: 'http://test.keycloak:8080',
          service_token: 'test-token',
        )
      end

      it 'returns service instance from database config' do
        service = described_class.for_connector('keycloak')

        expect(service).to be_a(Idp::KeycloakService)
        expect(service.send(:api_url)).to eq('http://test.keycloak:8080')
        expect(service.send(:client_secret)).to eq('test-token')
      end

      it 'uses database config over ENV variables' do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with('KEYCLOAK_API_URL').
          and_return('http://env.keycloak:9090')

        service = described_class.for_connector('keycloak')

        # Should use database config, not ENV
        expect(service.send(:api_url)).to eq('http://test.keycloak:8080')
      end
    end

    context 'without database config' do
      before do
        Idp::ServiceConfig.delete_all
      end

      it 'returns service instance from ENV config' do
        allow_any_instance_of(Idp::KeycloakService).
          to receive(:default_config).
          and_return({
                       api_url: 'http://env.keycloak:8080',
                       realm: 'env-realm',
                       client_id: 'env-client',
                       client_secret: 'env-secret',
                       org_id: 'env-org',
                     })

        service = described_class.for_connector('keycloak')

        expect(service).to be_a(Idp::KeycloakService)
      end
    end

    context 'with unknown connector' do
      # Fail-soft: a valid JWT from a connector with no config still authenticates
      # (UserProvisioner never calls this), so capability checks must degrade to a
      # NullService rather than raising and crashing the request.
      it 'returns a NullService carrying the connector_id, without raising' do
        service = described_class.for_connector('unknown_idp')

        expect(service).to be_a(Idp::NullService)
        expect(service.connector_id).to eq('unknown_idp')
        expect(service.supports_user_management?).to be(false)
      end
    end

    context 'with blank connector' do
      it 'returns a NullService without raising' do
        expect(described_class.for_connector(nil)).to be_a(Idp::NullService)
        expect(described_class.for_connector('')).to be_a(Idp::NullService)
      end
    end

    context 'with soft-deleted config' do
      let(:env_config) do
        { api_url: 'http://env.keycloak:8080', realm: 'env-realm', client_id: 'env-client', client_secret: 'env-secret' }
      end

      let!(:deleted_config) do
        config = create(
          :idp_service_config,
          connector_id: 'keycloak',
        )
        config.destroy
        config
      end

      it 'uses ENV config, ignoring deleted database config' do
        allow_any_instance_of(Idp::KeycloakService).to receive(:default_config).and_return(env_config)

        service = described_class.for_connector('keycloak')

        expect(service).to be_a(Idp::KeycloakService)
      end
    end

    context 'with inactive config' do
      let(:env_config) do
        { api_url: 'http://env.keycloak:8080', realm: 'env-realm', client_id: 'env-client', client_secret: 'env-secret' }
      end

      let!(:inactive_config) do
        create(
          :idp_service_config,
          connector_id: 'keycloak',
          active: false,
        )
      end

      it 'uses ENV config, ignoring inactive database config' do
        allow_any_instance_of(Idp::KeycloakService).to receive(:default_config).and_return(env_config)

        service = described_class.for_connector('keycloak')

        expect(service).to be_a(Idp::KeycloakService)
      end
    end
  end

  describe '.services' do
    it 'returns a hash of registered services' do
      services = described_class.services
      expect(services).to be_a(Hash)
      expect(services.keys).to include('keycloak')
    end

    it 'maps connector_id to service class' do
      services = described_class.services
      expect(services['keycloak']).to eq(Idp::KeycloakService)
    end
  end
end
