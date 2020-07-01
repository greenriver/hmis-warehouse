module GrdaWarehouse
  module Shape
    class CoC < GrdaWarehouseBase
      include SharedBehaviors

      def name
        cocname
      end

      def additional_geo_json_properties
        {
          'metric' => Random.rand
        }
      end

      def self.simplification_distance_in_degrees
        0.005
      end
    end
  end
end
