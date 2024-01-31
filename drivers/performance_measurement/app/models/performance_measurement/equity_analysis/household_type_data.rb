module PerformanceMeasurement::EquityAnalysis
  class HouseholdTypeData < PerformanceMeasurement::EquityAnalysis::Data
    def data_groups
      return HOUSEHOLD_TYPES unless household_type_params.any?

      HOUSEHOLD_TYPES.select { |k, _| household_type_params.include?(k) }
    end

    # We don't have census level household data
    def bars
      [
        'Current Period - Report Universe',
        'Comparison Period - Report Universe',
        'Current Period - Current Filters',
        'Comparison Period - Current Filters',
      ].freeze
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
      metric_scope(period).joins(:client_projects).merge(PerformanceMeasurement::ClientProject.where(household_type: investigate_by))
    end
  end
end
