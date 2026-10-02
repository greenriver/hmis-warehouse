###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::UsCensusApi::Finder, type: :model do
  let(:county) { GrdaWarehouse::Shape::County.create!(namelsad: 'Chittenden County', full_geoid: '0500000US50007') }

  before do
    travel_to Date.new(2026, 10, 2)
    { 2023 => 100, 2024 => 200 }.each do |year, value|
      variable = GrdaWarehouse::UsCensusApi::CensusVariable.create!(
        year: year,
        dataset: 'acs5',
        name: 'B01003_001E',
        label: 'Total',
        concept: 'Total population',
        census_group: 'B01003',
        census_attributes: 'B01003_001EA',
        internal_name: 'POP::TOTAL',
        created_on: Date.current,
      )
      GrdaWarehouse::UsCensusApi::CensusValue.create!(
        census_variable: variable,
        value: value,
        full_geoid: county.full_geoid,
        census_level: 'COUNTY',
        created_on: Date.current,
      )
    end
  end

  def finder(year)
    described_class.new(geometry: county, year: year, internal_names: ['POP::TOTAL'])
  end

  it 'uses the latest year with data when the requested year is newer' do
    result = finder(2025).best_value

    expect([result.year, result.val]).to eq([2024, 200])
  end

  it 'keeps a requested year that has data' do
    result = finder(2023).best_value

    expect([result.year, result.val]).to eq([2023, 100])
  end

  it 'rejects a year before 2009' do
    expect { finder(2008) }.to raise_error(RuntimeError, /valid year/)
  end
end
