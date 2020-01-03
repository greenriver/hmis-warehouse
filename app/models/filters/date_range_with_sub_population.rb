###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# provides validation for date ranges
module Filters
  class DateRangeWithSubPopulation < DateRange
    attribute :sub_population, Symbol, default: :all_clients

    validates_presence_of :start, :end, :sub_population


  end
end
