module GrdaWarehouse
  module Shape
    module SharedBehaviors
      extend ActiveSupport::Concern

      def geo_hash_geometry
        RGeo::GeoJSON.encode(geom)
      end

      def centroid
        @centroid ||= geom.centroid
      end

      def geo_json_properties
        {
          "id": id,
          "feature_type": self.class.name,
          "name": name,
          "centroid": [centroid.y, centroid.x],
        }.merge(additional_geo_json_properties)
      end

      def name
        'unknown'
      end

      def additional_geo_json_properties
        {}
      end

      module ClassMethods
        # Drastically reduce size of shapes and payload to send to the UI
        def simplify!
          # Save original if not done already
          where(orig_geom: nil).update_all(Arel.sql("orig_geom = geom"))

          # Reset geom (no-op the first time)
          update_all(Arel.sql("geom = orig_geom"))

          # Simplify
          # https://postgis.net/docs/ST_Simplify.html
          update_all(Arel.sql("geom = ST_MakeValid(ST_Simplify(geom, #{simplification_distance_in_degrees}))"))
        end
      end

      included do
        scope :efficient, -> { select(column_names - ['orig_geom']) }
      end
    end
  end
end
