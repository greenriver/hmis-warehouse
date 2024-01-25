module PerformanceMeasurement::EquityAnalysis
  class AgeData < PerformanceMeasurement::EquityAnalysis::Data
    def data_groups
      return AGES unless ages_params.any?

      AGES.select { |_, v| age_params.include?(v) }
    end

    def data
      x = [['x'] + data_groups.keys]
      columns = x + BARS.map { |bar| [bar] + data_groups.values.map { |group| bar_data(universe: bar, investigate_by: group) } }
      build_data.merge({ columns: columns })
    end

    def client_scope(period, investigate_by)
      age_range = Filters::FilterBase.age_range(investigate_by.to_sym)
      age_column = case period
      when 'reporting'
        :reporting_age
      else
        :comparison_age
      end
      metric_scope(period).where(age_column => age_range)
    end
  end
end
