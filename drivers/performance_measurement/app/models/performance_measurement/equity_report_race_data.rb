module PerformanceMeasurement
  class EquityReportRaceData < PerformanceMeasurement::EquityReportData
    def data_groups
      race_params.any? ? RACES.select { |k, _| race_params.include?(race_value_to_scope(k)) } : RACES
    end

    def data
      x = [['x'] + data_groups.values]
      {
        columns: x + BARS.map { |bar| [bar] + data_groups.keys.map { |group| bar_data(universe: bar, investigate_by: group) } },
        ordered_keys: BARS,
        colors: BARS.map.with_index { |bar, i| [bar, COLORS[i]] }.to_h,
      }
    end

    def bar_data(universe: nil, investigate_by: nil)
      race_scope = race_value_to_scope(investigate_by)
      scope = case universe
      when 'Current Period - Report Universe'
        # FIXME: should there be different values (reporting/comparison) for these
        metric_scope.send(race_scope)
      when 'Comparison Period - Report Universe'
        # FIXME: should there be different values (reporting/comparison) for these
        metric_scope.send(race_scope)
      when 'Current Period - Current Filters'
        # FIXME: should there be different values (reporting/comparison) for these
        apply_params(
          metric_scope.send(race_scope),
          'reporting',
        )
      when 'Comparison Period - Current Filters'
        # FIXME: should there be different values (reporting/comparison) for these
        apply_params(
          metric_scope.send(race_scope),
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
