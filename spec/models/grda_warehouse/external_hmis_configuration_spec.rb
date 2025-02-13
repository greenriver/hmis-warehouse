require 'rails_helper'

RSpec.describe GrdaWarehouse::ExternalHmisConfiguration, type: :model do
  let(:data_source) { create(:source_data_source) }
  let(:external_hmis_configuration) { described_class.new(data_source: data_source, base_url: 'https://example.com/', path_client: 'client/:personal_id:/profile') }

  describe '#active?' do
    it 'returns true when base_url is present' do
      expect(external_hmis_configuration.active?).to be true
    end

    it 'returns false when base_url is nil' do
      external_hmis_configuration.base_url = nil
      expect(external_hmis_configuration.active?).to be false
    end

    it 'returns false when base_url is an empty string' do
      external_hmis_configuration.base_url = ''
      expect(external_hmis_configuration.active?).to be false
    end
  end

  describe '#url' do
    let(:entity) { create(:hud_client, data_source: data_source) }

    context 'when active and entity is supported' do
      it 'returns a constructed URL' do
        expect(external_hmis_configuration.url(entity)).to eq("https://example.com/client/#{entity.personal_id}/profile")
      end
    end

    context 'when inactive' do
      before { external_hmis_configuration.base_url = nil }

      it 'returns nil' do
        expect(external_hmis_configuration.url(entity)).to be_nil
      end
    end

    it 'returns nil and logs an error when path_client is unknown' do
      external_hmis_configuration.path_client = 'clients/test'

      expect(external_hmis_configuration.url(entity)).to be_nil
      expect(Rails.logger).to receive(:error).with("Unknown external HMIS replacement pattern: #{external_hmis_configuration.path_client} in data source: #{data_source.id}")
      external_hmis_configuration.url(entity)
    end

    context 'when entity class is not in known integrations' do
      let(:unsupported_entity) { create(:hud_event, data_source: data_source) }

      it 'returns nil' do
        expect(external_hmis_configuration.url(unsupported_entity)).to be_nil
      end
    end
  end
end
