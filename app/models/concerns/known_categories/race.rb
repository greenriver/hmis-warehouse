###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module KnownCategories::Race
  extend ActiveSupport::Concern

  def race_calculations
    @race_calculations ||= {}.tap do |calcs|
      HudUtility2024.races.each do |key, title|
        next if key.to_sym == :RaceNone

        calcs[title] = ->(value) { value == key }
      end
      title = HudUtility2024.race('MultiRacial', multi_racial: true)
      calcs[title] = ->(value) { value == title }
      calcs['Client doesn\'t know'] = ->(value) { value == '8' }
      calcs['Client refused'] = ->(value) { value == '9' }
      calcs['Data not collected'] = ->(value) { value == '99' }
    end
  end

  def standard_race_calculation
    # See LSA for calculation logic
    columns = [
      c_t[:AmIndAKNative],
      c_t[:Asian],
      c_t[:BlackAfAmerican],
      c_t[:NativeHIPacific],
      c_t[:White],
      c_t[:HispanicLatinaeo],
      c_t[:MidEastNAfrican],
    ]
    conditions = [
      [Arel.sql(columns.map(&:to_sql).join(' + ')).between(2..98), 'MultiRacial'],
      [c_t[:RaceNone].eq(8), '8'],
      [c_t[:RaceNone].eq(9), '9'],
      [c_t[:AmIndAKNative].eq(1), 'AmIndAKNative'],
      [c_t[:Asian].eq(1), 'Asian'],
      [c_t[:BlackAfAmerican].eq(1), 'BlackAfAmerican'],
      [c_t[:NativeHIPacific].eq(1), 'NativeHIPacific'],
      [c_t[:White].eq(1), 'White'],
      [c_t[:HispanicLatinaeo].eq(1), 'HispanicLatinaeo'],
      [c_t[:MidEastNAfrican].eq(1), 'MidEastNAfrican'],
    ]
    acase(conditions, elsewise: '99')
  end
end
