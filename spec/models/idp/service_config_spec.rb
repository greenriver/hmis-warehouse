###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

RSpec.describe Idp::ServiceConfig, type: :model do
  describe 'validations' do
    subject { build(:idp_service_config) }

    it { is_expected.to validate_presence_of(:connector_id) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:api_url) }
    it { is_expected.to validate_presence_of(:service_token) }

    describe 'connector_id uniqueness' do
      let!(:existing) { create(:idp_service_config, connector_id: 'zitadel') }

      it 'prevents duplicate connector_id when both active' do
        config = build(:idp_service_config, connector_id: 'zitadel')
        expect(config).not_to be_valid
        expect(config.errors[:connector_id]).to be_present
      end

      it 'allows duplicate connector_id when one is soft-deleted' do
        existing.destroy
        config = build(:idp_service_config, connector_id: 'zitadel')
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
    it 'returns ZitadelService class for zitadel connector' do
      config = create(:idp_service_config, connector_id: 'zitadel')
      expect(config.service_class).to eq(Idp::ZitadelService)
    end

    it 'returns NullService for unknown connector' do
      config = create(
        :idp_service_config,
        connector_id: 'unknown_idp',
      )
      expect(config.service_class).to eq(Idp::NullService)
    end
  end

  describe '#to_service' do
    it 'instantiates ZitadelService with config values' do
      config = create(
        :idp_service_config,
        connector_id: 'zitadel',
        api_url: 'http://test.zitadel:8080',
        service_token: 'test-token',
        org_id: 'test-org',
        project_id: 'test-proj',
      )

      service = config.to_service
      expect(service).to be_a(Idp::ZitadelService)
      expect(service.send(:api_url)).to eq('http://test.zitadel:8080')
      expect(service.send(:token)).to eq('test-token')
      expect(service.send(:org_id)).to eq('test-org')
      expect(service.send(:project_id)).to eq('test-proj')
    end

    it 'instantiates NullService for unknown connector' do
      config = create(
        :idp_service_config,
        connector_id: 'unknown',
      )

      service = config.to_service
      expect(service).to be_a(Idp::NullService)
    end

    it 'preserves additional_config in service' do
      config = create(
        :idp_service_config,
        additional_config: { timeout: 30 },
      )

      service = config.to_service
      expect(service.config[:additional_config]).to include('timeout' => 30)
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
end
