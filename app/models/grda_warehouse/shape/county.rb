###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  module Shape
    class County < GrdaWarehouseBase
      include SharedBehaviors

      def self._full_geoid_prefix
        '0500000'
      end

      def self.simplification_distance_in_degrees
        0.0005
      end

      def name
        namelsad
      end
    end
  end
end
