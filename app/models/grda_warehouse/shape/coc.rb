###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  module Shape
    class CoC < GrdaWarehouseBase
      include SharedBehaviors

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
