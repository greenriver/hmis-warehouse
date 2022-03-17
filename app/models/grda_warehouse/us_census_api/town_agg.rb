###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# https://www.census.gov/content/dam/Census/data/developers/api-user-guide/api-guide.pdf
# https://www.census.gov/programs-surveys/geography/guidance/geo-identifiers.html

module GrdaWarehouse
  module UsCensusApi
    class TownAgg
      attr_accessor :town
      attr_accessor :value_tally
      attr_accessor :num_pieces
      attr_accessor :area_sum
      attr_accessor :results
      attr_accessor :candidates

      def self.run!
        Shape::Town.my_state.find_each do |town|
          puts town.town

          agg = new(town: town)
          agg.run!
          puts agg.results

          if (agg.results.good + agg.results.bad + agg.results.no_data).zero?
            raise "Looks like you don't have any data yet. Stopping"
            exit 1 # rubocop:disable Lint/UnreachableCode
          end
        end
      end

      def initialize(town:, candidates: nil) # rubocop:disable Lint/UnusedMethodArgument
        self.town = town
        self.value_tally = {}

        # Can also consider counties or zip codes. Any geometry that covers
        # the state completely can work if the code supports the geometry and
        # the census data exists.
        self.candidates ||= :candidate_zip_codes

        self.num_pieces = 0
        self.area_sum = 0.0
        self.results = Struct.new(:good, :bad, :no_data).new
        results.good = 0
        results.bad = 0
        results.no_data = 0
      end

      def run!
        _sanity_check!
        _collect_data!
        _safely_aggregate!
      end

      private

      def _sanity_check!
        raise "It doesn't make sense for a Town to have no candidate counties/block-groups/etc. Are you sure you loaded all the shapes for this state?" if town.send(self.candidates).none?
      end

      def _collect_data!
        town.send(self.candidates).find_each do |piece_of_town|
          intersection = town.geom.intersection(piece_of_town.geom)

          next if intersection.nil?

          area_in_town =
            if intersection.geometry_type.in?([RGeo::Feature::MultiPolygon, RGeo::Feature::Polygon])
              GrdaWarehouse::Shape::SpatialRefSys.to_meters(intersection).area
            else
              # We have to exclude points and lines that have no area
              intersection.
                reject { |shape| shape.geometry_type.in?([RGeo::Feature::LineString, RGeo::Feature::Point]) }.
                map { |shape| GrdaWarehouse::Shape::SpatialRefSys.to_meters(shape).area }.
                sum
            end

          area_of_piece_of_town = GrdaWarehouse::Shape::SpatialRefSys.to_meters(piece_of_town.geom).area

          percentage = area_in_town / area_of_piece_of_town

          # Debug by hijacking land area
          # piece_of_town.update_attribute(:aland, percentage)

          # want all the overlaps to be mostly inside or mostly outside.
          puts "Found a geometry that isn't clearly in any particular Town (#{(percentage * 100).round}%)." if percentage > 0.2 && percentage < 0.8

          # Skip over slivers that are computational artifacts
          next if percentage < 0.001

          self.num_pieces += 1
          self.area_sum += area_in_town

          piece_of_town.census_values.each do |census_value|
            value_tally[census_value.census_variable_id] ||= []

            # naively assign a percentage of a population value to a Town based purely on land area.
            value_tally[census_value.census_variable_id] << percentage * census_value.value
          end
        end
      end

      def _safely_aggregate!
        now = Date.today

        area_diff_sq_km = (_town_area - area_sum).abs / 1_000_000

        # With all the rounding and transforms, expect to be within 0.1%
        # don't sweat it when the result is very tiny.
        allowed_error = [_town_area / 1_000_000 * 0.001, 0.001].max

        raise "The areas didn't match up: #{area_diff_sq_km} with allowed error of #{allowed_error}" if area_diff_sq_km > allowed_error

        rows = []

        value_tally.each do |census_variable_id, values|
          if values.length != num_pieces
            # puts "FAIL: #{CensusVariable.find(census_variable_id).internal_name}"
            results.bad += 1
          elsif values.length.zero?
            # Don't set sum to 0 when there's no data!
            results.no_data += 1
          else
            # puts "GOOD: #{CensusVariable.find(census_variable_id).internal_name} with #{values.length} values"
            results.good += 1
            rows << [
              town.full_geoid,
              'CUSTOMTOWN',
              values.sum,
              census_variable_id,
              now,
            ]
          end
        end

        CensusValue.import(
          ['full_geoid', 'census_level', 'value', 'census_variable_id', 'created_on'],
          rows,
          on_duplicate_key_update: { conflict_target: ['full_geoid', 'census_variable_id'], columns: [:value] },
          raise_error: true,
        )
      end

      def _town_area
        @_town_area ||= GrdaWarehouse::Shape::SpatialRefSys.to_meters(town.geom).area
      end
    end
  end
end
