# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'

RSpec.describe Hmis::Hud::CustomServiceCategory, type: :model do
  let!(:data_source) { create(:hmis_data_source) }

  describe 'scopes' do
    before do
      ::HmisUtil::ServiceTypes.seed_hud_service_types(data_source.id)
    end

    let!(:empty_category) { create(:hmis_custom_service_category, data_source: data_source, name: 'Empty Category') }

    let!(:custom_only_category) { create(:hmis_custom_service_category, data_source: data_source, name: 'Custom Only') }
    let!(:custom_service_1) { create(:hmis_custom_service_type, custom_service_category: custom_only_category, data_source: data_source, name: 'Custom Service 1') }
    let!(:custom_service_2) { create(:hmis_custom_service_type, custom_service_category: custom_only_category, data_source: data_source, name: 'Custom Service 2') }

    describe '.hud_only' do
      it 'returns categories where all service types are HUD' do
        expect(described_class.hud_only.pluck(:name)).to match_array(HudHelper.util.record_types.values)
        expect(described_class.hud_only).not_to include(empty_category)
        expect(described_class.hud_only).not_to include(custom_only_category)
      end
    end

    describe '.custom_only' do
      it 'returns empty categories and categories where all service types are custom' do
        expect(described_class.custom_only).to contain_exactly(custom_only_category, empty_category)
      end
    end
  end
end
