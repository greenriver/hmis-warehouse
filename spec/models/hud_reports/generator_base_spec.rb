###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudReports::GeneratorBase, type: :model do
  describe '.report_definition_url' do
    let(:urls) { GrdaWarehouse::WarehouseReports::ReportDefinition::HUD_URLS }

    it 'reads registered generators first and retired generators from the aliases' do
      expect(HudApr::Generators::Apr::Fy2026::Generator.report_definition_url).to eq(urls[:aprs])
      expect(HudDataQualityReport::Generators::Fy2020::Generator.report_definition_url).to eq(urls[:dqs])
      expect(HudDataQualityReport::Generators::Fy2022::Generator.report_definition_url).to eq(urls[:dqs])
    end

    it 'raises for a generator in neither registry' do
      stub_const('UnregisteredHudGenerator', Class.new(described_class))

      expect { UnregisteredHudGenerator.report_definition_url }.to raise_error(KeyError)
    end
  end
end
