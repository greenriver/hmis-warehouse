###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module PerformanceMeasurement::EquityAnalysis
  class AgeData < PerformanceMeasurement::EquityAnalysis::Data
    def data_groups
      return AGES unless age_params.any?

      AGES.select { |_, v| age_params.include?(v) }
    end

    def data
      x = [['x'] + data_groups.keys]
      columns = x + bars.map do |bar|
        [bar] + data_groups.values.map do |group|
          bar_data(universe: bar, investigate_by: group)
        end
      end
      build_data.merge({ columns: columns })
    end

    def client_scope(period, investigate_by)
      age_range = census_age_range_to_range(investigate_by.to_sym)
      ages = age_range.to_a
      age_column = case period
      when 'reporting'
        :reporting_age
      else
        :comparison_age
      end
      metric_scope(period).where(age_column => ages)
    end
  end
end
