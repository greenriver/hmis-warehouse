###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  module Shape
    class County < GrdaWarehouseBase
      include SharedBehaviors
      include StateScopes

      scope :county_by_name, ->(names) do
        names.map!(&:downcase)
        where(arel_table[:namelsad].lower.in(names))
      end

      def self._full_geoid_prefix
        '0500000'
      end

      def self.simplification_distance_in_degrees
        0.0005
      end

      def name
        namelsad
      end

      def self.zip_codes
        ZipCode.joins(<<~SQL)
          JOIN shape_counties ON (
            LOWER(shape_counties.namelsad) = shape_zip_codes.county_name_lower
          )
        SQL
      end

      def self.spatial_zip_codes
        ZipCode.joins(<<~SQL)
          JOIN shape_counties ON (
            ST_Area(
              ST_Intersection(shape_zip_codes.simplified_geom, shape_counties.simplified_geom)
            )
            >=
            (0.5 * ST_Area(shape_zip_codes.simplified_geom))
          )
        SQL
      end

      def zip_codes
        ZipCode.joins(<<~SQL)
          JOIN shape_counties ON (
            shape_counties.id = #{id}
            AND
            LOWER(shape_counties.namelsad) = shape_zip_codes.county_name_lower
          )
        SQL
      end

      def spatial_zip_codes
        ZipCode.joins(<<~SQL)
          JOIN shape_counties ON (
            shape_counties.id = #{id}
            AND
            ST_Area(
              ST_Intersection(shape_zip_codes.simplified_geom, shape_counties.simplified_geom)
            )
            >=
            (0.5 * ST_Area(shape_zip_codes.simplified_geom))
          )
        SQL
      end
    end
  end
end
