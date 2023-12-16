module PerformanceMeasurement
  class EquityReportAgeData < PerformanceMeasurement::EquityReportData
    def data_groups
      age_params.any? ? AGES.select { |_, v| age_params.include?(v) } : AGES
    end

    def data
      x = [['x'] + data_groups.keys]
      {
        columns: x + BARS.map { |bar| [bar] + data_groups.values.map { |group| bar_data(universe: bar, investigate_by: group) } },
        ordered_keys: BARS,
        colors: BARS.map.with_index { |bar, i| [bar, COLORS[i]] }.to_h,
      }
    end

    def bar_data(universe: nil, investigate_by: nil)
      age_range = Filters::FilterBase.age_range(investigate_by.to_sym)
      scope = case universe
      when 'Current Period - Report Universe'
        metric_scope.where(reporting_age: age_range)
      when 'Comparison Period - Report Universe'
        metric_scope.where(comparison_age: age_range)
      when 'Current Period - Current Filters'
        apply_params(
          metric_scope.where(reporting_age: age_range),
          'reporting',
        )
      when 'Comparison Period - Current Filters'
        apply_params(
          metric_scope.where(comparison_age: age_range),
          'comparison',
        )
      end
      scope.count
    end

    def chart_height
      calculate_height(data_groups)
    end
  end
end
