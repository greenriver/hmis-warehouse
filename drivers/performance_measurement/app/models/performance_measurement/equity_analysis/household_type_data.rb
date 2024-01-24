module PerformanceMeasurement::EquityAnalysis
  class HouseholdTypeData < PerformanceMeasurement::EquityAnalysis::Data
    def data_groups
      return HOUSEHOLD_TYPES unless household_type_params.any?

      HOUSEHOLD_TYPES.select { |k, _| household_type_params.include?(k) }
    end

    def data
      x = [['x'] + data_groups.values]
      columns = x + BARS.map { |bar| [bar] + data_groups.keys.map { |group| bar_data(universe: bar, investigate_by: group) } }
      build_data.merge({ columns: columns })
    end

    def client_scope(period, investigate_by)
      metric_scope(period).joins(:client_projects).merge(PerformanceMeasurement::ClientProject.where(household_type: investigate_by))
    end
  end
end