###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TxClientReports::ResearchExport, type: :model do
  let(:export) { described_class.new }
  let(:util) { HudHelper.util }

  describe '#demographic_headers' do
    subject(:headers) { export.demographic_headers }

    it 'includes all 2026 gender labels' do
      expect(headers).to include(*util.gender_field_name_label.values)
    end

    it 'includes Sex header' do
      expect(headers).to include('Sex')
    end

    it 'includes Sex after the last gender column and before the first race column' do
      last_gender_index = headers.rindex { |h| util.gender_field_name_label.values.include?(h) }
      sex_index = headers.index('Sex')
      first_race_index = headers.index { |h| util.races.values.include?(h) }

      expect(sex_index).to eq(last_gender_index + 1)
      expect(sex_index).to be < first_race_index
    end

    it 'includes all 2026 race labels including HispanicLatinaeo' do
      expect(headers).to include(*util.races.values)
    end

    it 'does not include Ethnicity' do
      expect(headers).not_to include('Ethnicity')
    end

    it 'does not include legacy-only gender labels' do
      legacy_only = HudHelper.util('legacy').genders.values - HudHelper.util.gender_field_name_label.values
      expect(headers & legacy_only).to be_empty
    end
  end

  describe '#format_demographic_value' do
    let(:headers) { export.demographic_headers }

    it 'formats gender values as yes/no/missing' do
      gender_header_index = headers.index(util.gender_field_name_label.values.first)
      expect(export.format_demographic_value(1, gender_header_index)).to eq('Yes')
      expect(export.format_demographic_value(0, gender_header_index)).to eq('No')
      expect(export.format_demographic_value(99, gender_header_index)).to eq('Data not collected')
    end

    it 'formats race values as yes/no/missing' do
      race_header_index = headers.index(util.races.values.first)
      expect(export.format_demographic_value(1, race_header_index)).to eq('Yes')
      expect(export.format_demographic_value(0, race_header_index)).to eq('No')
      expect(export.format_demographic_value(99, race_header_index)).to eq('Data not collected')
    end

    it 'formats RaceNone values using the full missing-data vocabulary' do
      race_none_index = headers.index(util.race_field_name_to_description['RaceNone'])
      expect(export.format_demographic_value(0, race_none_index)).to be_nil
      expect(export.format_demographic_value(8, race_none_index)).to eq("Client doesn't know")
      expect(export.format_demographic_value(9, race_none_index)).to eq('Client prefers not to answer')
      expect(export.format_demographic_value(99, race_none_index)).to eq('Data not collected')
    end

    it 'formats Sex values as descriptive labels' do
      sex_index = headers.index('Sex')
      expect(export.format_demographic_value(0, sex_index)).to eq('Female')
      expect(export.format_demographic_value(1, sex_index)).to eq('Male')
      expect(export.format_demographic_value(99, sex_index)).to eq('Data not collected')
    end

    it 'passes through non-demographic values unchanged' do
      warehouse_id_index = headers.index('Warehouse ID')
      expect(export.format_demographic_value(42, warehouse_id_index)).to eq(42)
    end
  end
end
