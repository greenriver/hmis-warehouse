###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::UsCensusApi::Finder, type: :model do
  let(:county) { GrdaWarehouse::Shape::County.create!(namelsad: 'Chittenden County', full_geoid: '0500000US50007') }

  around do |example|
    travel_to(Date.new(2026, 10, 2)) { example.run }
  end

  before do
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

  it 'rejects a year newer than the data once it is five years behind today' do
    travel_to(Date.new(2031, 10, 2))

    expect { finder(2026) }.to raise_error(RuntimeError, /valid year/)
  end

  it 'falls back to the latest data year while the request is under five years behind today' do
    travel_to(Date.new(2031, 10, 2))

    result = finder(2027).best_value

    expect([result.year, result.val]).to eq([2024, 200])
  end

  it 'raises CannotFindData when one of the requested variables has no value' do
    finder = described_class.new(geometry: county, year: 2023, internal_names: ['POP::TOTAL', 'POP::MISSING'])

    expect { finder.best_value }.to raise_error(described_class::CannotFindData, /POP::MISSING/)
  end

  it 'sums the values of every requested variable' do
    male = GrdaWarehouse::UsCensusApi::CensusVariable.create!(
      year: 2023,
      dataset: 'acs5',
      name: 'B01001_002E',
      label: 'Male',
      concept: 'Sex by age',
      census_group: 'B01001',
      census_attributes: 'B01001_002EA',
      internal_name: 'POP::MALE',
      created_on: Date.current,
    )
    GrdaWarehouse::UsCensusApi::CensusValue.create!(
      census_variable: male,
      value: 40,
      full_geoid: county.full_geoid,
      census_level: 'COUNTY',
      created_on: Date.current,
    )
    finder = described_class.new(geometry: county, year: 2023, internal_names: ['POP::TOTAL', 'POP::MALE'])

    result = finder.best_value

    expect([result.val, result.components.size]).to eq([140, 2])
  end
end
