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
      period = universe_period(universe)
      scope = case universe
      when 'Current Period - Report Universe'
        metric_scope(period).send(race_scope)
      when 'Comparison Period - Report Universe'
        metric_scope(period).send(race_scope)
      when 'Current Period - Current Filters'
        apply_params(
          metric_scope(period).send(race_scope),
          period,
        )
      when 'Comparison Period - Current Filters'
        apply_params(
          metric_scope(period).send(race_scope),
          period,
        )
      end
      scope.count
    end
  end
end
