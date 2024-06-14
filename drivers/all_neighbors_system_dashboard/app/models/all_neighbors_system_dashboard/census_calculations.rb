###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AllNeighborsSystemDashboard
  module CensusCalculations
    extend ActiveSupport::Concern
    include GrdaWarehouse::UsCensusApi::Aggregates
    included do
      private def get_us_census_population_by_race(race_code: 'All', year:)
        race_var = case race_code
        when 'AmIndAKNative' then NATIVE_AMERICAN
        when 'Asian' then ASIAN
        when 'BlackAfAmerican' then BLACK
        when 'NativeHIPacific' then PACIFIC_ISLANDER
        when 'White' then WHITE
        when 'RaceNone', '', nil then OTHER_RACE
        when 'MultiRacial' then TWO_OR_MORE_RACES
        when 'All' then ALL_PEOPLE
        else
          raise "Invalid race code: #{race_code}"
        end
        result = state_geometry.population(internal_names: race_var, year: year)

        if result.error
          Rails.logger.error "population error: #{result.msg}. Sum won't be right!"
          return nil
        elsif result.year != year
          Rails.logger.warn "Using #{result.year} instead of #{year}"
        end

        result.val
      end

      private def state_geometry
        # NOTE: this is not in use at the moment,
        # and this report is only designed to work with one state
        @state_geometry ||= GrdaWarehouse::Shape::State.my_states.first
      end
    end
  end
end
