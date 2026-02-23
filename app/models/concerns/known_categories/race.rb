###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module KnownCategories::Race
  extend ActiveSupport::Concern

  def race_calculations
    @race_calculations ||= {}.tap do |calcs|
      HudHelper.util.race_ethnicity_combinations.each do |key, title|
        next if key == :race_none

        calcs[title] = ->(value) { value == key.to_s }
      end
      calcs['Client doesn\'t know'] = ->(value) { value == '8' }
      calcs['Client prefers not to answer'] = ->(value) { value == '9' }
      calcs['Data not collected'] = ->(value) { value == '99' }
    end
  end

  def standard_race_calculation
    # Calculate race + HispanicLatinaeo combinations
    race_columns = [
      c_t[:AmIndAKNative],
      c_t[:Asian],
      c_t[:BlackAfAmerican],
      c_t[:NativeHIPacific],
      c_t[:White],
      c_t[:MidEastNAfrican],
    ]
    race_sum = race_columns.reduce(:+)

    race_mappings = {
      c_t[:AmIndAKNative] => 'am_ind_ak_native',
      c_t[:Asian] => 'asian',
      c_t[:BlackAfAmerican] => 'black_af_american',
      c_t[:NativeHIPacific] => 'native_hi_pacific',
      c_t[:White] => 'white',
      c_t[:MidEastNAfrican] => 'mid_east_n_african',
    }

    conditions = [
      [c_t[:RaceNone].eq(8), '8'],
      [c_t[:RaceNone].eq(9), '9'],
      [c_t[:RaceNone].eq(99), '99'],
      [race_sum.gt(1).and(c_t[:HispanicLatinaeo].eq(1)), 'multi_racial_hispanic_latinaeo'],
      [race_sum.gt(1), 'multi_racial'],
    ]

    race_mappings.each do |race_column, race_key|
      single_race_condition = race_column.eq(1).and(race_sum.eq(1))
      conditions << [single_race_condition.and(c_t[:HispanicLatinaeo].eq(1)), "#{race_key}_hispanic_latinaeo"]
      conditions << [single_race_condition, race_key]
    end

    conditions << [c_t[:HispanicLatinaeo].eq(1).and(race_sum.eq(0)), 'hispanic_latinaeo']

    acase(conditions, elsewise: 'race_none')
  end
end
