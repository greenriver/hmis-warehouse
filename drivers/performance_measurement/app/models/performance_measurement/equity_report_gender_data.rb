module PerformanceMeasurement
  class EquityReportGenderData < PerformanceMeasurement::EquityReportData
    def data_groups
      gender_params.any? ? GENDERS.select { |k, _| gender_params.include?(gender_value_to_scope(k)) } : GENDERS
    end

    def data
      x = [['x'] + data_groups.values]
      columns = x + BARS.map { |bar| [bar] + data_groups.keys.map { |group| bar_data(universe: bar, investigate_by: group) } }
      build_data.merge({ columns: columns })
    end

    def client_scope(period, investigate_by)
      gender_scope = gender_value_to_scope(investigate_by)
      metric_scope(period).send(gender_scope)
    end
  end
end
