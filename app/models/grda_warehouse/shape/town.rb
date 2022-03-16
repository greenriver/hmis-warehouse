###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  module Shape
    class Town < GrdaWarehouseBase
      include SharedBehaviors
      include StateScopes

      def candidate_zip_codes
        ZipCode.joins(Arel.sql(<<~SQL))
          join shape_towns ON (
            ST_Intersects(
              shape_towns.simplified_geom,
              shape_zip_codes.simplified_geom
            )
            AND
            shape_towns.id = #{id}
          )
        SQL
      end

      def self._full_geoid_prefix
        'CUSTOMTOWN'
      end

      def self._geoid_column
        'town'
      end

      def name
        read_attribute(:town)
      end

      def self.simplification_distance_in_degrees
        0.0005
      end
    end
  end
end
