###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  module Shape
    class Place < GrdaWarehouseBase
      include SharedBehaviors

      def name
        read_attribute(:name)
      end

      def self._full_geoid_prefix
        "1600000"
      end

      def self.simplification_distance_in_degrees
        0.0005
      end
    end
  end
end
