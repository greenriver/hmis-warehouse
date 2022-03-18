###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module KnownCategories::Age
  extend ActiveSupport::Concern

  def age_calculations
    @age_calculations ||= {}.tap do |calcs|
      calcs['< 1 yr old'] = {
        lambda: ->(value) { value.zero?(0) },
        where_clause: age_calculation.eq(0),
        column: age_calculation,
      }
      [
        [1, 5],
        [6, 13],
        [14, 17],
        [18, 21],
        [19, 24],
        [25, 30],
        [31, 35],
        [36, 40],
        [41, 45],
        [46, 50],
        [51, 55],
        [56, 60],
        [61, 62],
      ].each do |one, two|
        calcs["#{one} - #{two} yrs old"] = {
          lambda: ->(value) { value.in?(one..two) },
          where_clause: age_calculation.between(one, two),
          column: age_calculation,
        }
      end
      calcs['63+ yrs old'] = {
        lambda: ->(value) { value >= 63 },
        where_clause: age_calculation.gteq(63),
        column: age_calculation,
      }

      calcs['Missing'] = {
        lambda: ->(value) { value.blank? },
        where_clause: c_t[:DOB].eq(nil),
        column: c_t[:DOB],
      }
    end
  end

  def standard_age_calculation
    age_calculation
  end
end
