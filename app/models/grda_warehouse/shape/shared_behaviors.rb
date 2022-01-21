###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  module Shape
    module SharedBehaviors
      extend ActiveSupport::Concern

      def geo_hash_geometry
        RGeo::GeoJSON.encode(simplified_geom)
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

      def population(args = {})
        args[:geometry] = self
        UsCensusApi::Finder.new(args).best_value
      end

      module ClassMethods
        # Drastically reduce size of shapes and payload to send to the UI
        def simplify!
          # Simplify
          # https://postgis.net/docs/ST_Simplify.html
          where(simplified_geom: nil).update_all(Arel.sql("simplified_geom = ST_MakeValid(ST_Simplify(geom, #{simplification_distance_in_degrees}))"))
        end

        # This is the id the census returns
        def set_full_geoid!
          where(full_geoid: nil).update_all("full_geoid = '#{Arel.sql(_full_geoid_prefix)}' || 'US' || #{_geoid_column}")
        end

        def _full_geoid_prefix
          raise "Please set the full geoid prefix in #{name} and try again"
        end

        # Often just geoid, but some datasets call it geoid10
        def _geoid_column
          'geoid'
        end

        def my_fips_state_code
          @my_fips_state_code ||= State.find_by!(stusps: ENV['RELEVANT_COC_STATE']).geoid
        end
      end

      included do
        scope :efficient, -> { select(column_names - ['geom', 'simplified_geom']) }

        has_many :census_values, foreign_key: :full_geoid, primary_key: :full_geoid, class_name: 'GrdaWarehouse::UsCensusApi::CensusValue'
      end
    end
  end
end
