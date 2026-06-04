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
          org_id: 'test-org',
        )
      end

      it 'returns service instance from database config' do
        service = described_class.for_connector('keycloak')

        expect(service).to be_a(Idp::KeycloakService)
        expect(service.send(:api_url)).to eq('http://test.keycloak:8080')
        expect(service.send(:client_secret)).to eq('test-token')
        expect(service.config[:org_id]).to eq('test-org')
      end

      it 'uses database config over ENV variables' do
        allow(ENV).to receive(:fetch).with('KEYCLOAK_API_URL', anything).
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
                       client_secret: 'env-secret',
                       org_id: 'env-org',
                       project_id: 'env-proj',
                     })

        service = described_class.for_connector('keycloak')

        expect(service).to be_a(Idp::KeycloakService)
      end
    end

    context 'with unknown connector' do
      it 'returns NullService' do
        service = described_class.for_connector('unknown_idp')

        expect(service).to be_a(Idp::NullService)
      end
    end

    context 'with soft-deleted config' do
      let!(:deleted_config) do
        config = create(
          :idp_service_config,
          connector_id: 'keycloak',
        )
        config.destroy
        config
      end

      it 'uses ENV config, ignoring deleted database config' do
        service = described_class.for_connector('keycloak')

        expect(service).to be_a(Idp::KeycloakService)
        # Should fall back to ENV since database config is deleted
      end
    end

    context 'with inactive config' do
      let!(:inactive_config) do
        create(
          :idp_service_config,
          connector_id: 'keycloak',
          active: false,
        )
      end

      it 'uses ENV config, ignoring inactive database config' do
        service = described_class.for_connector('keycloak')

        expect(service).to be_a(Idp::KeycloakService)
        # Should fall back to ENV since database config is inactive
      end
    end
  end

  describe '.idp_supports_feature?' do
    context 'with Keycloak connector' do
      before do
        create(
          :idp_service_config,
          connector_id: 'keycloak',
          api_url: 'http://test.keycloak:8080',
          service_token: 'test-secret',
          additional_config: { client_id: 'test-client' },
        )
      end

      it 'supports user_management feature' do
        result = described_class.idp_supports_feature?('keycloak', :user_management)
        expect(result).to be true
      end

      it 'supports profile_updates feature' do
        result = described_class.idp_supports_feature?('keycloak', :profile_updates)
        expect(result).to be true
      end

      it 'does not support unknown feature' do
        result = described_class.idp_supports_feature?('keycloak', :unknown_feature)
        expect(result).to be false
      end
    end

    context 'with unknown connector' do
      it 'returns false for any feature' do
        result = described_class.idp_supports_feature?('unknown', :user_management)
        expect(result).to be false
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
