###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  module Shape
    class BlockGroup < GrdaWarehouseBase
      include SharedBehaviors
      include StateScopes

      def self._full_geoid_prefix
        '1500000'
      end

      def self.simplification_distance_in_degrees
        0.0005
      end
    end
  end
end
