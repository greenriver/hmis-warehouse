module PerformanceMeasurement::EquityAnalysis
  class RaceEthnicityData < PerformanceMeasurement::EquityAnalysis::Data
    def data_groups
      return RACE_ETHNICITY_COMBINATIONS unless race_ethnicity_params.any?

      RACE_ETHNICITY_COMBINATIONS.select { |k, _| race_ethnicity_params.include?(race_ethnicity_value_to_scope(k)) }
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
      scope = race_ethnicity_value_to_scope(investigate_by)
      metric_scope(period).send(scope)
    end
  end
end
