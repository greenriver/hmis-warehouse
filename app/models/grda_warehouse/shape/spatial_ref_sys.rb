###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Code initially written for and funded by Delaware Health and Social Services.
# Used and modified with permission.

module GrdaWarehouse
  module Shape
    class SpatialRefSys < GrdaWarehouseBase
      self.table_name = 'spatial_ref_sys'

      # https://epsg.io/4326
      DEFAULT_SRID = 4326

      DEFAULT_METERS_SRID = 32618

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
        if RGeo::CoordSys::Proj4.supported?
          RGeo::Feature.cast(geom, :factory => meters_factory, :project => true)
        else
          Rails.logger.error "Cannot convert to meters since rgeo was not compiled with proj support. You're computing with degrees now."
          geom
        end
      end
    end
  end
end
