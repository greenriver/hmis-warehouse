###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# provides validation for date ranges
module Filters
  class DisabilitiesReportFilter < DateRangeWithSubPopulation
    attribute :disabilities, Array, lazy: true, default: []
    attribute :project_types, Array, lazy: true, default: []

    validates_presence_of :disabilities, :project_types
  end
end
