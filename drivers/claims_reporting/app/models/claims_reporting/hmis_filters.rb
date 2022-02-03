###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

###
###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
module ClaimsReporting
  # performs a similar function to ::Filter::FilterScopes
  # but that expects a scope that is joinable to "clients"
  module HmisFilters
    def hud_clients_scope
      scope = GrdaWarehouse::Hud::Client.all
      scope = filter_for_race(scope)
      scope = filter_for_ethnicity(scope)
      scope = filter_for_gender(scope)
      scope
    end

    private def filtered_by_client?
      filter.races.present? || filter.ethnicities.present? || filter.genders.present?
    end

    private def c_t
      GrdaWarehouse::Hud::Client.arel_table
    end

    private def filter_for_race(scope)
      return scope unless filter.races.present?

      # puts "HmisFilters: applying races=#{filter.races}"

      keys = filter.races.map(&:to_s)
      # Remove RaceNone from the possibilities, it can't be a 1
      race_columns = GrdaWarehouse::Hud::Client.race_fields - ['RaceNone']
      selected_races = (keys & race_columns)
      multi_racial_scope = GrdaWarehouse::Hud::Client.multi_racial

      scope = scope.merge(GrdaWarehouse::Hud::Client.with_races(selected_races)) if selected_races.any?

      if keys.include?('MultiRacial')
        scope = if selected_races.any?
          scope.or(multi_racial_scope)
        else
          scope.merge(multi_racial_scope)
        end
      end
      scope
    end

    private def filter_for_ethnicity(scope)
      return scope unless filter.ethnicities.present?

      # puts "HmisFilters: applying ethnicities=#{filter.ethnicities}"

      scope.where(c_t[:Ethnicity].in(filter.ethnicities))
    end

    private def filter_for_gender(scope)
      return scope unless filter.genders.present?

      # puts "HmisFilters: applying genders=#{filter.genders}"

      scope.where(c_t[:Gender].in(filter.genders))
    end

    private def filter_for_age(scope, as_of: Date.current)
      return scope unless @filter.age_ranges.present? && (@filter.available_age_ranges.values & @filter.age_ranges).present?

      # puts "HmisFilters: applying age_ranges=#{filter.age_ranges}"

      # Or'ing ages is very slow, instead we'll build up an acceptable
      # array of ages
      ages = []
      ages += (0..17).to_a if @filter.age_ranges.include?(:under_eighteen)
      ages += (18..24).to_a if @filter.age_ranges.include?(:eighteen_to_twenty_four)
      ages += (25..29).to_a if @filter.age_ranges.include?(:twenty_five_to_twenty_nine)
      ages += (30..39).to_a if @filter.age_ranges.include?(:thirty_to_thirty_nine)
      ages += (40..49).to_a if @filter.age_ranges.include?(:forty_to_forty_nine)
      ages += (50..54).to_a if @filter.age_ranges.include?(:fifty_to_fifty_four)
      ages += (55..59).to_a if @filter.age_ranges.include?(:fifty_five_to_fifty_nine)
      ages += (60..61).to_a if @filter.age_ranges.include?(:sixty_to_sixty_one)
      ages += (62..110).to_a if @filter.age_ranges.include?(:over_sixty_one)

      at = ClaimsReporting::MemberRoster.arel_table
      age_calculation = Arel::Nodes::NamedFunction.new(
        'AGE',
        [Arel::Nodes::Quoted.new(as_of), at[:date_of_birth]],
      )

      scope.joins(:member_roster).where(
        Arel.sql("EXTRACT(YEAR FROM #{age_calculation.to_sql})").in(ages),
      )
    end
  end
end
