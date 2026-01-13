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
          connector_id: 'zitadel',
          api_url: 'http://test.zitadel:8080',
          service_token: 'test-token',
          org_id: 'test-org',
        )
      end

      it 'returns service instance from database config' do
        service = described_class.for_connector('zitadel')

        expect(service).to be_a(Idp::ZitadelService)
        expect(service.send(:api_url)).to eq('http://test.zitadel:8080')
        expect(service.send(:token)).to eq('test-token')
        expect(service.send(:org_id)).to eq('test-org')
      end

      it 'uses database config over ENV variables' do
        allow(ENV).to receive(:fetch).with('ZITADEL_API_URL', anything).
          and_return('http://env.zitadel:9090')

        service = described_class.for_connector('zitadel')

        # Should use database config, not ENV
        expect(service.send(:api_url)).to eq('http://test.zitadel:8080')
      end
    end

    context 'without database config' do
      before do
        Idp::ServiceConfig.delete_all
      end

      it 'returns service instance from ENV config' do
        allow_any_instance_of(Idp::ZitadelService).
          to receive(:default_config).
          and_return({
                       api_url: 'http://env.zitadel:8080',
                       service_token: 'env-token',
                       org_id: 'env-org',
                       project_id: 'env-proj',
                     })

        service = described_class.for_connector('zitadel')

        expect(service).to be_a(Idp::ZitadelService)
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
          connector_id: 'zitadel',
        )
        config.destroy
        config
      end

      it 'uses ENV config, ignoring deleted database config' do
        service = described_class.for_connector('zitadel')

        expect(service).to be_a(Idp::ZitadelService)
        # Should fall back to ENV since database config is deleted
      end
    end

    context 'with inactive config' do
      let!(:inactive_config) do
        create(
          :idp_service_config,
          connector_id: 'zitadel',
          active: false,
        )
      end

      it 'uses ENV config, ignoring inactive database config' do
        service = described_class.for_connector('zitadel')

        expect(service).to be_a(Idp::ZitadelService)
        # Should fall back to ENV since database config is inactive
      end
    end
  end

  describe '.idp_supports_feature?' do
    context 'with Zitadel connector' do
      it 'supports user_management feature' do
        result = described_class.idp_supports_feature?('zitadel', :user_management)
        expect(result).to be true
      end

      it 'supports profile_updates feature' do
        result = described_class.idp_supports_feature?('zitadel', :profile_updates)
        expect(result).to be true
      end

      it 'does not support unknown feature' do
        result = described_class.idp_supports_feature?('zitadel', :unknown_feature)
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
      expect(services.keys).to include('zitadel')
    end

    it 'maps connector_id to service class' do
      services = described_class.services
      expect(services['zitadel']).to eq(Idp::ZitadelService)
    end
  end
end
