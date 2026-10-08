###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublicReports::StateDashboard::Geography, type: :model do
  subject(:geography) { described_class.new('place') }

  let!(:state) { GrdaWarehouse::Shape::State.create!(stusps: 'MA', geoid: '25') }

  before do
    # GrdaWarehouse::Shape classes memoize their state-code lookup on the
    # class object itself, so it survives an example's transaction rollback
    # and can leak a stale (pre-fixture) empty result into a later example.
    GrdaWarehouse::Shape::Town.instance_variable_set(:@my_fips_state_codes, nil)
  end

  def create_town(name, west:)
    GrdaWarehouse::Shape::Town.create!(
      town: name,
      statefp: state.geoid,
      geom: "SRID=4326;MULTIPOLYGON(((#{west} 42.0, #{west + 0.1} 42.0, #{west + 0.1} 42.1, #{west} 42.1, #{west} 42.0)))",
    )
  end

  describe '#svg' do
    it 'builds one path per geography, with coordinates in the 0..720 viewBox and a positive height' do
      create_town('TESTVILLE', west: -71.5)

      svg = geography.svg

      expect(svg[:paths].size).to eq(1)
      index, slug, d = svg[:paths].first
      expect(index).to eq(0)
      expect(slug).to eq('testville')
      expect(d).to start_with('M')

      height = svg[:view_box].split(' ').last.to_f
      expect(height).to be > 0

      coordinates = d.scan(/-?\d+(?:\.\d+)?/).map(&:to_f)
      xs = coordinates.each_slice(2).map(&:first)
      ys = coordinates.each_slice(2).map(&:last)
      expect(xs).to all(be_between(0, 720))
      expect(ys).to all(be_between(0, height))
    end

    it 'orders paths by name, matching the index order of #codes' do
      create_town('ZEDBURY', west: -71.5)
      create_town('ABINGTON', west: -71.0)

      slugs = geography.svg[:paths].map { |index, slug, _d| [index, slug] }

      expect(geography.codes).to eq(['ABINGTON', 'ZEDBURY'])
      expect(slugs).to eq([[0, 'abington'], [1, 'zedbury']])
    end

    it 'returns an empty map when the state has no shapes' do
      expect(geography.svg).to eq(view_box: '0 0 720 0', paths: [])
    end
  end

  describe '#codes' do
    it 'excludes towns in a state the installation does not cover' do
      create_town('TESTVILLE', west: -71.5)
      other_state = GrdaWarehouse::Shape::State.create!(stusps: 'NH', geoid: '33')
      GrdaWarehouse::Shape::Town.create!(
        town: 'NASHUA',
        statefp: other_state.geoid,
        geom: 'SRID=4326;MULTIPOLYGON(((-71.5 42.7, -71.4 42.7, -71.4 42.8, -71.5 42.8, -71.5 42.7)))',
      )

      expect(geography.codes).to eq(['TESTVILLE'])
      expect(geography.svg[:paths].map { |_index, slug, _d| slug }).to eq(['testville'])
    end

    it 'uses the CoC number as the code and "name (number)" as the display name' do
      GrdaWarehouse::Shape::Coc.create!(st: 'MA', cocnum: 'MA-500', cocname: 'Boston')
      GrdaWarehouse::Shape::Coc.create!(st: 'NH', cocnum: 'NH-500', cocname: 'Manchester')
      coc_geography = described_class.new('coc')

      expect(coc_geography.codes).to eq(['MA-500'])
      expect(coc_geography.display_name('MA-500')).to eq('Boston (MA-500)')
    end
  end

  describe '#population_by_race' do
    let(:coc_geography) { described_class.new('coc') }
    let(:total_population_variable) do
      GrdaWarehouse::UsCensusApi::CensusVariable.create!(
        year: 2024, dataset: 'acs5', name: 'B01003_001E', label: 'POP::TOTAL', concept: 'Total Population',
        census_group: 'B01003', census_attributes: 'B01003_001EA', internal_name: 'POP::TOTAL', created_on: Date.current
      )
    end

    def create_coc(cocnum, population: nil)
      coc = GrdaWarehouse::Shape::Coc.create!(st: 'MA', cocnum: cocnum, cocname: cocnum, full_geoid: "CUSTOMCOCUS#{cocnum}")
      return if population.nil?

      GrdaWarehouse::UsCensusApi::CensusValue.create!(
        census_variable: total_population_variable, value: population, full_geoid: coc.full_geoid, census_level: 'CUSTOM', created_on: Date.current,
      )
    end

    it 'sums the census population across the state CoCs' do
      create_coc('MA-500', population: 1_000)
      create_coc('MA-501', population: 500)

      expect(coc_geography.population_by_race(year: 2024)).to eq(1_500)
    end

    it 'returns nil when any CoC has no census value for the year' do
      create_coc('MA-500', population: 1_000)
      create_coc('MA-501')

      expect(coc_geography.population_by_race(year: 2024)).to be_nil
    end
  end

  describe '#svg caching' do
    around do |example|
      original_cache = Rails.cache
      Rails.cache = ActiveSupport::Cache::MemoryStore.new
      example.run
    ensure
      Rails.cache = original_cache
    end

    it 'does not serve one map type the cached SVG of another' do
      create_town('TESTVILLE', west: -71.5)

      place_paths = described_class.new('place').svg[:paths].size
      zip_paths = described_class.new('zip').svg[:paths].size

      expect([place_paths, zip_paths]).to eq([1, 0])
    end
  end
end
