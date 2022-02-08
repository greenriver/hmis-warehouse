###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# provides validation for date ranges
module Filters
  class DateRangeWithSubPopulation < DateRange
    attribute :sub_population, Symbol, default: :clients

    validates_presence_of :start, :end, :sub_population
  end
end
