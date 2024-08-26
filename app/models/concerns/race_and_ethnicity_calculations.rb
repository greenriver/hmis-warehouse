###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module RaceAndEthnicityCalculations
  extend ActiveSupport::Concern

  def race_ethnicities_breakdowns(scope)
    race_ethnicities_breakdown = race_ethnicity_combinations.values.map { |m| [m, Set[]] }.to_h

    race_data = pluck_to_hash((['id'] + race_col_lookup.keys.excluding('race_none')).map { |k, v| [k, v] }.to_h, scope)
    race_ethnicity_combinations.each do |key, value|
      race_ethnicities_breakdown[value] = race_and_ethnicity_lookups[key]&.call(race_data)
    end
    race_ethnicities_breakdown
  end

  def race_col_lookup
    HudUtility2024.races.map { |k, _| [k.underscore, k] }.to_h
  end

  private def pluck_to_hash(columns, scope)
    scope.pluck(*columns.keys).map do |row|
      Hash[columns.keys.zip(row)]
    end
  end

  private def single_race(race_data, race)
    [].tap do |ids|
      race_data.select { |enrollment| enrollment[race] && !enrollment['hispanic_latinaeo'] }.
        each { |e| ids << e['id'] if e.excluding('id', 'hispanic_latinaeo').count { |m| m.count(true) == 1 } == 1 }
    end
  end

  private def single_race_latinaeo(race_data, race)
    [].tap do |ids|
      race_data.select { |enrollment| enrollment[race] && enrollment['hispanic_latinaeo'] }.
        each { |e| ids << e['id'] if e.excluding('id', 'hispanic_latinaeo').count { |m| m.count(true) == 1 } == 1 }
    end
  end

  private def only_hispanic_latinaeo(race_data)
    [].tap do |ids|
      race_data.select { |enrollment| enrollment['hispanic_latinaeo'] }.
        each { |e| ids << e['id'] if e.excluding('id').count { |m| m.count(true) == 1 } == 1 }
    end
  end

  private def multi_racial(race_data)
    [].tap do |ids|
      race_data.reject { |enrollment| enrollment['hispanic_latinaeo'] }.
        each { |e| ids << e['id'] if e.excluding('id', 'hispanic_latinaeo').count { |m| m.count(true) == 1 } > 1 }
    end
  end

  private def multi_racial_with_hispanic_latinaeo(race_data)
    [].tap do |ids|
      race_data.select { |enrollment| enrollment['hispanic_latinaeo'] }.
        each { |e| ids << e['id'] if e.excluding('id', 'hispanic_latinaeo').count { |m| m.count(true) == 1 } > 1 }
    end
  end

  private def race_none(race_data)
    [].tap do |ids|
      race_data.each { |e| ids << e['id'] if e.except('id').values.all?(false) }
    end
  end

  private def race_and_ethnicity_lookups
    {
      am_ind_ak_native: ->(race_data) { single_race(race_data, 'am_ind_ak_native') },
      am_ind_ak_native_hispanic_latinaeo: ->(race_data) { single_race_latinaeo(race_data, 'am_ind_ak_native') },
      asian: ->(race_data) { single_race(race_data, 'asian') },
      asian_hispanic_latinaeo: ->(race_data) { single_race_latinaeo(race_data, 'asian') },
      black_af_american: ->(race_data) { single_race(race_data, 'black_af_american') },
      black_af_american_hispanic_latinaeo: ->(race_data) { single_race_latinaeo(race_data, 'black_af_american') },
      mid_east_n_african: ->(race_data) { single_race(race_data, 'mid_east_n_african') },
      mid_east_n_african_hispanic_latinaeo: ->(race_data) { single_race_latinaeo(race_data, 'mid_east_n_african') },
      native_hi_pacific: ->(race_data) { single_race(race_data, 'native_hi_pacific') },
      native_hi_pacific_hispanic_latinaeo: ->(race_data) { single_race_latinaeo(race_data, 'native_hi_pacific') },
      white: ->(race_data) { single_race(race_data, 'white') },
      white_hispanic_latinaeo: ->(race_data) { single_race_latinaeo(race_data, 'white') },
      hispanic_latinaeo: ->(race_data) { only_hispanic_latinaeo(race_data) },
      multi_racial: ->(race_data) { multi_racial(race_data) },
      multi_racial_hispanic_latinaeo: ->(race_data) { multi_racial_with_hispanic_latinaeo(race_data) },
      race_none: ->(race_data) { race_none(race_data) },
    }.freeze
  end

  private def race_ethnicity_combinations
    HudUtility2024.race_ethnicity_combinations
  end
end
