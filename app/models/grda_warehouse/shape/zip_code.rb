###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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

      scope :my_states, -> { in_state(my_fips_state_codes) }
      scope :not_my_states, -> { where.not(id: in_state(my_fips_state_codes).select(:id)) }
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
              (shape_zip_codes.geom && shape_states.geom)
              and
              (
                ST_Area(ST_Intersection(shape_zip_codes.geom, shape_states.geom))
                /
                ST_Area(shape_zip_codes.geom)
                >
                0.95
              )
            )
          SQL
      end

      def self.all_we_need?
        count >= 33_000
      end

      def self.calculate_states
        connection.execute(<<~SQL)
          UPDATE
            shape_zip_codes AS z
          SET
            st_geoid = s.geoid
          FROM
            shape_states s
          WHERE
            z.st_geoid IS NULL
            AND
              (
                ST_Area(ST_Intersection(z.geom, s.geom))
                /
                ST_Area(z.geom)
                >
                0.95
              )
        SQL
      end

      def self.calculate_counties(state_codes = GrdaWarehouse::Shape::State.my_fips_state_codes)
        connection.execute(<<~SQL)
          UPDATE
            shape_zip_codes AS z
          SET
            county_name_lower = LOWER(namelsad)
          FROM
            shape_counties c
          WHERE
            z.county_name_lower IS NULL
            AND z.st_geoid in (#{state_codes.map { |m| "'#{m}'" }.join(',')})
            AND
              (
                ST_Area(ST_Intersection(z.geom, c.geom))
                /
                ST_Area(z.geom)
                >
                0.95
              )
        SQL
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
              ST_Intersection(shape_zip_codes.geom, shape_counties.geom)
            )
            >=
            (0.5 * ST_Area(shape_zip_codes.geom))
          )
        SQL
      end

      def self.spatial_counties
        joins(<<~SQL)
          JOIN shape_counties ON (
            ST_Area(
              ST_Intersection(shape_zip_codes.geom, shape_counties.geom)
            )
            >=
            (0.5 * ST_Area(shape_zip_codes.geom))
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
