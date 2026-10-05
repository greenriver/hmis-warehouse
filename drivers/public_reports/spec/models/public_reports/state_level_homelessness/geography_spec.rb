###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublicReports::StateLevelHomelessness::Geography, type: :model do
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
end
