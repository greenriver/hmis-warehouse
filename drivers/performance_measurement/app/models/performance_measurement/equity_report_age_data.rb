module PerformanceMeasurement
  class EquityReportAgeData < PerformanceMeasurement::EquityReportData
    def data_groups
      age_params.any? ? AGES.select { |_, v| age_params.include?(v) } : AGES
    end

    def data
      x = [['x'] + data_groups.keys]
      columns = x + BARS.map { |bar| [bar] + data_groups.values.map { |group| bar_data(universe: bar, investigate_by: group) } }
      build_data.merge({ columns: columns })
    end

    def client_scope(period, investigate_by)
      age_range = Filters::FilterBase.age_range(investigate_by.to_sym)
      period == 'reporting' ? metric_scope(period).where(reporting_age: age_range) : metric_scope(period).where(comparison_age: age_range)
    end
  end
end
