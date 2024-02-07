module PerformanceMeasurement::EquityAnalysis
  class GenderData < PerformanceMeasurement::EquityAnalysis::Data
    def data_groups
      return GENDERS unless gender_params.any?

      GENDERS.select { |k, _| gender_params.include?(gender_value_to_scope(k)) }
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
      gender_scope = gender_value_to_scope(investigate_by)
      metric_scope(period).send(gender_scope)
    end
  end
end
