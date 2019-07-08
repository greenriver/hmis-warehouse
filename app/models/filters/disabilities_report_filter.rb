###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# provides validation for date ranges
module Filters
  class DisabilitiesReportFilter < DateRangeWithSubPopulation
    attribute :disabilities, Array, lazy: true, default: []
    attribute :project_types, Array, lazy: true, default: []
  end
end