###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# We need states to figure out which zip codes they contain and as a lookup for
# fips state codes

module GrdaWarehouse
  module Shape
    class State < GrdaWarehouseBase
      include SharedBehaviors
      include StateScopes

      def self._full_geoid_prefix
        '0400000'
      end

      def self.simplification_distance_in_degrees
        0.005
      end
    end
  end
end
