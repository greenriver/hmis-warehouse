###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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

      def additional_geo_json_properties
        {}
      end

      def population(args = {})
        args[:geometry] = self
        UsCensusApi::Finder.new(args).best_value
      end

      module ClassMethods
        # Drastically reduce size of shapes and payload to send to the UI
        def simplify!(force: false)
          # Simplify
          # https://postgis.net/docs/ST_Simplify.html
          scope = if force
            where(Arel.sql('1=1'))
          else
            where(simplified_geom: nil)
          end
          simplified = nf('ST_MakeValid', [nf('ST_Simplify', [arel_table[:geom], simplification_distance_in_degrees])])
          scope.update_all(simplified_geom: simplified)
        end

        # This is the id the census returns
        def set_full_geoid!
          # `||` rather than CONCAT so that a null geoid leaves full_geoid null (and thus
          # still eligible) instead of writing a prefix-only value
          geoid = Arel::Nodes::Concat.new(qt("#{_full_geoid_prefix}US"), arel_table[_geoid_column])
          where(full_geoid: nil).update_all(full_geoid: geoid)
        end

        def _full_geoid_prefix
          raise "Please set the full geoid prefix in #{name} and try again"
        end

        # Often just geoid, but some datasets call it geoid10
        def _geoid_column
          'geoid'
        end

        def my_fips_state_codes
          @my_fips_state_codes ||= State.where(stusps: GrdaWarehouse::Config.relevant_state_codes).map(&:geoid)
        end

        def all_we_need?
          count.positive?
        end
      end

      included do
        scope :efficient, -> { select(column_names - ['geom', 'simplified_geom']) }

        has_many :census_values, foreign_key: :full_geoid, primary_key: :full_geoid, class_name: 'GrdaWarehouse::UsCensusApi::CensusValue'
      end
    end
  end
end
