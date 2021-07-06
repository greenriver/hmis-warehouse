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

      scope :in_state, ->(state_fips) {
        where(shape_states: { geoid: state_fips })
        .joins(Arel.sql(<<~SQL))
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
      }

      def name
        zcta5ce10
      end

      def additional_geo_json_properties
        {
          'metric' => Random.rand
        }
      end

      def self.simplification_distance_in_degrees
        0.0005
      end
    end
  end
end
