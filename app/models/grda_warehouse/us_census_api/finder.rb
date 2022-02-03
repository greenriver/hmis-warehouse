###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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

      def initialize(args={})
        self.geometry = args[:geometry]
        self.year = args[:year] || Date.today.year-3
        self.internal_names = args[:internal_names] || Aggregates::ALL_PEOPLE

        # fall back to last year we have data for if we're not too far from it.
        this_year = Date.today.year
        if self.year > max_year && (this_year - self.year < 5)
          Rails.logger.debug { "Using #{max_year} instead of #{self.year} for census values" }
          self.year = max_year
        end

        if Array.wrap(self.year).any? { |y| y.to_i < 2009 || y.to_i > max_year }
          raise "You must specify a valid year for #{self.geometry.name}: #{self.year}"
        end
      end

      # UsCensusApi::Finder.new(geometry: , year: 2019, internal_names: UsCensusApi::Aggregates::BLACK).best_value
      def best_value
        if internal_names.length > 1
          raise "[#{internal_names.join(', ')}] Only supporting single variable requests for speed. We can upgrade to multi-variable requests if needed"
        else
          # sort by distance from requested year then prefer dicennial censu.
          result = geometry
            .census_values
            .includes(:census_variable)
            .where(census_variables: {internal_name: internal_names})
            .order(Arel.sql("abs(census_variables.year - #{self.year}) asc, CASE WHEN dataset='sf1' THEN 0 ELSE 1 END asc"))
            .first

          if result.blank?
            # not sure how we want to handle this in this app
            # raise CannotFindData, "Cannot find values for #{internal_names} for #{geometry.full_geoid} for #{year} in #{dataset}!"
            Results.new(nil, [], "Cannot find values for #{internal_names} for #{geometry.full_geoid} for #{year} ", true, nil, nil)
          else
            Results.new(result.value, [result], "success", false, result.year, result.dataset)
          end
        end
      end

      private

      def max_year
        @@max_year ||=
          Rails.cache.fetch("census-latest-data-year", expires_in: 1.hour) do
            CensusVariable.joins(:census_values).maximum(:year) || Date.current.year
          end
      end
    end
  end
end
