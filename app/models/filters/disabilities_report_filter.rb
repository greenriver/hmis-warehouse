###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# provides validation for date ranges
module Filters
  class DisabilitiesReportFilter < DateRangeWithSubPopulation
    attribute :disabilities, Array, lazy: true, default: [].freeze
    attribute :project_types, Array, lazy: true, default: [].freeze

    validates_presence_of :disabilities, :project_types
  end
end
