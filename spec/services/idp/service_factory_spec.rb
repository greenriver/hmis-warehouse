###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

RSpec.describe Idp::ServiceFactory, :jwt_only, type: :model do
  describe '.for_connector' do
    context 'with an active database config' do
      let!(:config) do
        create(
          :idp_service_config,
          connector_id: 'keycloak',
          api_url: 'http://test.keycloak:8080',
          service_token: 'test-token',
        )
      end

      it 'returns the managed service instance built from the row' do
        service = described_class.for_connector('keycloak')

        expect(service).to be_a(Idp::KeycloakService)
        expect(service.send(:api_url)).to eq('http://test.keycloak:8080')
        expect(service.send(:client_secret)).to eq('test-token')
      end
    end

    context 'with an inactive database config' do
      let!(:inactive_config) do
        create(:idp_service_config, connector_id: 'keycloak', active: false)
      end

      # The DB row is the single source of truth, so a deactivated row is an
      # explicit "turn this connector off" that degrades to unmanaged.
      it 'returns a NullService carrying the connector_id' do
        service = described_class.for_connector('keycloak')

        expect(service).to be_a(Idp::NullService)
        expect(service.connector_id).to eq('keycloak')
        expect(service.supports_user_management?).to be(false)
      end
    end

    context 'with no database config' do
      before { Idp::ServiceConfig.delete_all }

      # Fail-soft: a valid JWT from a connector with no config still authenticates
      # (UserProvisioner never calls this), so capability checks must degrade to a
      # NullService rather than raising and crashing the request.
      it 'returns a NullService carrying the connector_id, without raising' do
        service = described_class.for_connector('keycloak')

        expect(service).to be_a(Idp::NullService)
        expect(service.connector_id).to eq('keycloak')
        expect(service.supports_user_management?).to be(false)
      end
    end

    context 'with an unknown connector' do
      it 'returns a NullService carrying the connector_id, without raising' do
        service = described_class.for_connector('unknown_idp')

        expect(service).to be_a(Idp::NullService)
        expect(service.connector_id).to eq('unknown_idp')
        expect(service.supports_user_management?).to be(false)
      end
    end

    context 'with a blank connector' do
      it 'returns a NullService without raising' do
        expect(described_class.for_connector(nil)).to be_a(Idp::NullService)
        expect(described_class.for_connector('')).to be_a(Idp::NullService)
      end
    end

    context 'with both an inactive and an active row for the same connector_id' do
      # Deactivating must not strand a connector: a fresh active row for the same
      # connector_id restores the managed service via the active scope.
      let!(:inactive_config) do
        create(:idp_service_config, connector_id: 'keycloak', active: false)
      end

      let!(:active_config) do
        create(
          :idp_service_config,
          connector_id: 'keycloak',
          api_url: 'http://test.keycloak:8080',
          service_token: 'test-token',
        )
      end

      it 'prefers the active row and builds the managed service' do
        service = described_class.for_connector('keycloak')

        expect(service).to be_a(Idp::KeycloakService)
        expect(service.config[:api_url]).to eq('http://test.keycloak:8080')
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
