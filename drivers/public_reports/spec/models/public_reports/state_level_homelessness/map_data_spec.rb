###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PublicReports::StateLevelHomelessness::MapData, type: :model do
  subject(:map_data) { described_class.new(PublicReports::StateLevelHomelessness.new) }

  describe '#snap_rate' do
    context 'with percentage-of-homeless-population bands' do
      before { PublicReports::Setting.first_or_create.update!(map_overall_population_method: 'state') }

      it 'snaps each rate to the top of its band' do
        snapped = [0, 0.1, 10.0, 10.1, 25.0, 25.1].map { |rate| map_data.snap_rate(rate) }

        expect(snapped).to eq([0, 10.0, 10.0, 15.0, 25.0, 100.0])
      end

      it 'snaps a rate above every band to the top band' do
        expect(map_data.snap_rate(150.0)).to eq(100.0)
      end
    end

    context 'with census rate-per-10,000 bands' do
      before { PublicReports::Setting.first_or_create.update!(map_overall_population_method: 'geography') }

      it 'snaps each rate to the top of its band' do
        snapped = [3.0, 3.1, 18.0, 18.1].map { |rate| map_data.snap_rate(rate) }

        expect(snapped).to eq([3.0, 6.0, 18.0, 100.0])
      end
    end
  end
end
