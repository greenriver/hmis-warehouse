###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# provides validation for date ranges
module Filters
  class DateRangeWithSubPopulation < DateRange
    attribute :sub_population, Symbol, default: :clients

    validates_presence_of :start, :end, :sub_population
  end
end
