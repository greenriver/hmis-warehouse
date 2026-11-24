###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# The RRH outcomes report limited to the Performance Metrics sub-population.
module PerformanceMetrics::Outcomes
  class RrhReport < WarehouseReport::Outcomes::RrhReport
    def housed_source
      PerformanceMetrics::OutcomesSubPopulation.new(filter.sub_population).restrict(super)
    end
  end
end
