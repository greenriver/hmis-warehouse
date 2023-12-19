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
      {
        columns: x + BARS.map { |bar| [bar] + data_groups.map { |group| bar_data(universe: bar, investigate_by: group) } },
        ordered_keys: BARS,
        colors: BARS.map.with_index { |bar, i| [bar, COLORS[i]] }.to_h,
      }
    end

    # def bar_data(universe: nil, investigate_by: nil)
    def bar_data(*)
      # FIXME
      rand(100)
    end
  end
end
