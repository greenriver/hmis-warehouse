###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module KnownCategories::Age
  extend ActiveSupport::Concern

  def age_calculations
    @age_calculations ||= {}.tap do |calcs|
      calcs['< 1 yr old'] = ->(value) { value&.zero? }
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
        calcs["#{one} - #{two} yrs old"] = ->(value) { value.in?(one..two) }
      end
      calcs['63+ yrs old'] = ->(value) { value.present? && value >= 63 }
      calcs['Missing'] = ->(value) { value.blank? }
    end
  end

  def standard_age_calculation
    age_calculation
  end
end
