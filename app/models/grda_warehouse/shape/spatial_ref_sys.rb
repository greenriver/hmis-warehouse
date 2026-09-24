###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Code initially written for and funded by Delaware Health and Social Services.
# Used and modified with permission.

module GrdaWarehouse
  module Shape
    class SpatialRefSys < GrdaWarehouseBase
      self.table_name = 'spatial_ref_sys'

      # https://epsg.io/4326
      DEFAULT_SRID = 4326

      # https://epsg.io/5070 NAD83 Conus Albers: equal-area across the continental US.
      # A single UTM zone folds polygons from other zones into self-intersecting rings.
      DEFAULT_METERS_SRID = 5070

      # Padded area of use for EPSG 5070; Alaska, Hawaii, and the territories fall outside it.
      METERS_LON_RANGE = (-126.0..-66.0)
      METERS_LAT_RANGE = (24.0..50.0)

      OutsideProjectionArea = Class.new(StandardError)

      def self.default
        where(srid: DEFAULT_SRID).first!
      end

      def self.default_factory
        @default_factory ||= RGeo::Cartesian.factory(:srid => DEFAULT_SRID, proj4: default.proj4text)
      end

      def self.meters_factory
        proj4 = find_by(srid: DEFAULT_METERS_SRID).proj4text

        @meters_factory ||= RGeo::Cartesian.factory(:srid => DEFAULT_METERS_SRID, proj4: proj4)
      end

      def self.to_meters(geom)
        check_projection_area!(geom)

        if RGeo::CoordSys::Proj4.supported?
          # Projection rounding can turn thin boundary slivers into self-intersecting rings,
          # which rgeo refuses to measure.
          RGeo::Feature.cast(geom, :factory => meters_factory, :project => true).make_valid
        else
          Rails.logger.error "Cannot convert to meters since rgeo was not compiled with proj support. You're computing with degrees now."
          geom
        end
      end

      def self.check_projection_area!(geom)
        return if geom.empty?

        center = geom.centroid
        return if METERS_LON_RANGE.cover?(center.x) && METERS_LAT_RANGE.cover?(center.y)

        raise OutsideProjectionArea, "Geometry centered at (#{center.x}, #{center.y}) is outside the EPSG #{DEFAULT_METERS_SRID} area; add a projection for it before computing areas"
      end
    end
  end
end
