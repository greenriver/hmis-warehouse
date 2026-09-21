###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublicReports::StateLevelHomelessness, type: :model do
  describe '#map_svg' do
    it 'builds one path per geography, with coordinates in the 0..720 viewBox and a positive height' do
      # GrdaWarehouse::Shape classes memoize their state-code lookup on the
      # class object itself (not Rails.cache), so it survives this example's
      # transaction rollback and can leak a stale (pre-fixture) empty result
      # into a later example. Force a fresh lookup for this run.
      GrdaWarehouse::Shape::Town.instance_variable_set(:@my_fips_state_codes, nil)
      Rails.cache.clear

      state = GrdaWarehouse::Shape::State.create!(stusps: 'MA', geoid: '25')
      GrdaWarehouse::Shape::Town.create!(
        town: 'TESTVILLE',
        statefp: state.geoid,
        geom: 'SRID=4326;MULTIPOLYGON(((-71.5 42.0, -71.4 42.0, -71.4 42.1, -71.5 42.1, -71.5 42.0)))',
      )
      PublicReports::Setting.first_or_create.update!(map_type: 'place')

      svg = described_class.new.map_svg

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
  end
end
