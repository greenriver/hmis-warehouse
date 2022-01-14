###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  module Shape
    class ZipCode < GrdaWarehouseBase
      include SharedBehaviors

      def self._full_geoid_prefix
        '8600000'
      end

      def self._geoid_column
        'geoid10'
      end

      scope :my_state, -> { in_state(my_fips_state_code) }
      scope :not_my_state, -> { where.not(id: in_state(my_fips_state_code).select(:id)) }
      scope :missing_assigned_county, -> { where(county_name_lower: nil) }
      scope :missing_assigned_state, -> { where(st_geoid: nil) }

      scope :in_state, ->(st_geoid) do
        where(shape_states: { geoid: st_geoid }).
          joins(Arel.sql(<<~SQL))
            join shape_states ON (shape_zip_codes.st_geoid = shape_states.geoid)
          SQL
      end

      scope :spatial_in_state, ->(st_geoid) do
        where(shape_states: { geoid: st_geoid }).
          joins(Arel.sql(<<~SQL))
            join shape_states ON (
              (shape_zip_codes.simplified_geom && shape_states.simplified_geom)
              and
              (
                ST_Area(ST_Intersection(shape_zip_codes.simplified_geom, shape_states.simplified_geom))
                /
                ST_Area(shape_zip_codes.simplified_geom)
                >
                0.95
              )
            )
          SQL
      end

      def self.calculate_states
        State.pluck(:geoid).each do |geoid|
          missing_assigned_state.spatial_in_state(geoid).each do |zip|
            zip.update(st_geoid: geoid)
          end
        end
      end

      def self.calculate_counties
        missing_assigned_county.each do |zip|
          zip.update(county_name_lower: zip.spatial_county.first&.namelsad&.downcase)
        end
      end

      def county
        County.joins(<<~SQL)
          JOIN shape_zip_codes ON (
            shape_zip_codes.id = #{id}
            AND
            LOWER(shape_counties.namelsad) = shape_zip_codes.county_name_lower
          )
        SQL
      end

      def self.counties
        joins(<<~SQL)
          JOIN shape_counties ON (LOWER(shape_counties.namelsad) = shape_zip_codes.county_name_lower)
        SQL
      end

      def spatial_county
        County.joins(<<~SQL)
          JOIN shape_zip_codes ON (
            shape_zip_codes.id = #{id}
            AND
            ST_Area(
              ST_Intersection(shape_zip_codes.simplified_geom, shape_counties.simplified_geom)
            )
            >=
            (0.5 * ST_Area(shape_zip_codes.simplified_geom))
          )
        SQL
      end

      def self.spatial_counties
        joins(<<~SQL)
          JOIN shape_counties ON (
            ST_Area(
              ST_Intersection(shape_zip_codes.simplified_geom, shape_counties.simplified_geom)
            )
            >=
            (0.5 * ST_Area(shape_zip_codes.simplified_geom))
          )
        SQL
      end

      def name
        zcta5ce10
      end

      def additional_geo_json_properties
        {
          'metric' => Random.rand,
        }
      end

      def self.simplification_distance_in_degrees
        0.0005
      end
    end
  end
end
