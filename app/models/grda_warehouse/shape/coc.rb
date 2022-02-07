###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  module Shape
    class CoC < GrdaWarehouseBase
      include SharedBehaviors

      scope :my_state, -> { where(st: ENV['RELEVANT_COC_STATE']) }
      scope :not_my_state, -> { where.not(st: ENV['RELEVANT_COC_STATE']) }

      def candidate_block_groups
        BlockGroup.joins(Arel.sql(<<~SQL))
          join shape_cocs ON (
            ST_Intersects(
              shape_cocs.simplified_geom,
              shape_block_groups.simplified_geom
            )
            AND
            shape_cocs.id = #{id}
          )
        SQL
      end

      def candidate_counties
        County.joins(Arel.sql(<<~SQL))
          join shape_cocs ON (
            ST_Intersects(
              shape_cocs.simplified_geom,
              shape_counties.simplified_geom
            )
            AND
            shape_cocs.id = #{id}
          )
        SQL
      end

      def self._full_geoid_prefix
        'CUSTOMCOC'
      end

      def self._geoid_column
        'cocnum'
      end

      def name
        cocname
      end

      def number_and_name
        "#{cocname} (#{cocnum})"
      end

      def additional_geo_json_properties
        {
          cocnum: cocnum,
          cocname: cocname,
        }
      end

      def self.simplification_distance_in_degrees
        0.005
      end
    end
  end
end
