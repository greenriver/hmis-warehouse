###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::Shape::SpatialRefSys, type: :model do
  let(:factory) { RGeo::Cartesian.factory(srid: described_class::DEFAULT_SRID) }

  def square(lon, lat)
    corners = [
      factory.point(lon, lat),
      factory.point(lon + 1, lat),
      factory.point(lon + 1, lat + 1),
      factory.point(lon, lat + 1),
      factory.point(lon, lat),
    ]
    factory.polygon(factory.linear_ring(corners))
  end

  describe '.to_meters' do
    it 'projects a continental US geometry into EPSG 5070 square meters' do
      result = described_class.to_meters(square(-112, 33))

      expect(result.srid).to eq(5070)
      # One degree of longitude at 33N is ~93 km and one degree of latitude ~111 km.
      expect(result.area).to be_between(9.5e9, 1.1e10)
    end

    it 'raises for a geometry centered in Alaska' do
      expect { described_class.to_meters(square(-150, 64)) }.to raise_error(described_class::OutsideProjectionArea, /-149.5, 64.5/)
    end

    it 'raises for a geometry centered in Hawaii' do
      expect { described_class.to_meters(square(-156, 20)) }.to raise_error(described_class::OutsideProjectionArea)
    end

    it 'passes an empty geometry through without checking its location' do
      expect(described_class.to_meters(factory.collection([]))).to be_empty
    end
  end
end
