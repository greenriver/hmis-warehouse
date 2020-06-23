###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# provides validation for date ranges
module Filters
  class DateRangeWithSubPopulation < DateRange
    attribute :sub_population, Symbol, default: :clients
    attribute :age_ranges, Array, default: []
    attribute :heads_of_household, Boolean, default: false

    validates_presence_of :start, :end, :sub_population

    def available_age_ranges
      {
        under_eighteen: '< 18',
        eighteen_to_twenty_four: '18 - 24',
        twenty_five_to_sixty_one: '25 - 61',
        over_sixty_one: '62+',
      }.invert.freeze
    end
  end
end
