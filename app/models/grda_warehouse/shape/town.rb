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

      def name
        read_attribute(:town)
      end

      def self._full_geoid_prefix
        '1600000'
      end

      def self.simplification_distance_in_degrees
        0.0005
      end
    end
  end
end
