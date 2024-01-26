###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Code initially written for and funded by Delaware Health and Social Services.
# Used and modified with permission.
#
module GrdaWarehouse
  module UsCensusApi
    class Finder
      Results = Struct.new(:val, :components, :msg, :error, :year, :dataset)

      CannotFindData = Class.new(StandardError)

      attr_accessor :geometry
      attr_accessor :year
      attr_accessor :internal_names

      def initialize(args = {})
        self.geometry = args[:geometry]
        self.year = args[:year] || Date.today.year - 3
        self.internal_names = args[:internal_names] || Aggregates::ALL_PEOPLE

        # fall back to last year we have data for if we're not too far from it.
        this_year = Date.today.year
        if year > max_year && (this_year - year < 5)
          Rails.logger.debug { "Using #{max_year} instead of #{year} for census values" }
          year = max_year
        end

        raise "You must specify a valid year for #{geometry.name}: #{year}" if Array.wrap(year).any? { |y| y.to_i < 2009 || y.to_i > max_year }
      end

      # UsCensusApi::Finder.new(geometry: , year: 2019, internal_names: UsCensusApi::Aggregates::BLACK).best_value
      def best_value
        return Results.new(0, [], 'success', false, year, nil) if internal_names.empty?

        # sort by distance from requested year then prefer dicennial census.
        # cache result based on geometry, internal_names, and year for 24 hours
        Rails.cache.fetch("census-#{geometry.full_geoid}-#{internal_names}-#{year}", expires_in: 1.day) do
          results = internal_names.map do |internal_name|
            geometry.
              census_values.
              includes(:census_variable).
              where(census_variables: { internal_name: internal_name }).
              order(Arel.sql("abs(census_variables.year - #{year}) asc, CASE WHEN dataset='sf1' THEN 0 ELSE 1 END asc")).
              first
          end

          raise CannotFindData, "Cannot find values for #{internal_names} for #{geometry.full_geoid} for #{year}!" if results.any?(&:blank?)

          Results.new(results.sum(&:value), results, 'success', false, year, results.first.dataset)
        end
      end

      private def max_year
        @max_year ||= Rails.cache.fetch('census-latest-data-year', expires_in: 1.hour) do
          CensusVariable.joins(:census_values).maximum(:year) || Date.current.year
        end
      end
    end
  end
end
