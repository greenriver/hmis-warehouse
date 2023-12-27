# FIXME FAKE DATA
module PerformanceMeasurement
  class EquityReportHouseholdTypeData < PerformanceMeasurement::EquityReportData
    def data_groups
      # FIXME
      household_type_params.any? ? HOUSEHOLD_TYPES.select { |v| household_type_params.include?(v) } : HOUSEHOLD_TYPES
    end

    def data
      # FIXME
      x = [['x'] + data_groups]
      columns = x + BARS.map { |bar| [bar] + data_groups.map { |group| bar_data(universe: bar, investigate_by: group) } }
      build_data.merge({ columns: columns })
    end

    def client_scope(period, _)
      # FIXME
      metric_scope(period)
    end
  end
end
