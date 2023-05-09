###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
