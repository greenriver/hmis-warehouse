###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module PerformanceMeasurement::EquityAnalysis
  class SexData < PerformanceMeasurement::EquityAnalysis::Data
    def data_groups
      return SEXES unless sex_params.any?

      SEXES.select { |k, _| sex_params.include?(sex_value_to_scope(k)) }
    end

    def data
      x = [['x'] + data_groups.values]
      columns = x + bars.map do |bar|
        [bar] + data_groups.keys.map do |group|
          bar_data(universe: bar, investigate_by: group)
        end
      end
      build_data.merge({ columns: columns })
    end

    def client_scope(period, investigate_by)
      sex_scope = sex_value_to_scope(investigate_by)
      metric_scope(period).send(sex_scope)
    end
  end
end
