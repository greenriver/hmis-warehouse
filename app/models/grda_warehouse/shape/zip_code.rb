###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  module Shape
    class ZipCode < GrdaWarehouseBase
      include SharedBehaviors

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
