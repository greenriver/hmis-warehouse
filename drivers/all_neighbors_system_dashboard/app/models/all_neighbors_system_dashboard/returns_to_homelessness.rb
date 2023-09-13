module AllNeighborsSystemDashboard
  class ReturnsToHomelessness < FakeData
    def data(title, id, type, options: {})
      keys = (options[:types] || []).map { |key| to_key(key) }
      {
        title: title,
        id: id,
        demographics: demographics.map do |demo|
          bars = ['Exited*', 'Returned']
          demo_names_meth = "demographic_#{demo.gsub(' ', '').underscore}".to_sym
          demo_colors_meth = "demographic_#{demo.gsub(' ', '').underscore}_colors".to_sym
          names = send(demo_names_meth)
          keys = names.map { |key| to_key(key) }
          colors = send(demo_colors_meth)
          {
            demographic: demo,
            config: {
              keys: keys,
              names: keys.map.with_index { |key, i| [key, names[i]] }.to_h,
              colors: keys.map.with_index { |key, i| [key, colors[i]] }.to_h,
              label_colors: keys.map { |key| [key, '#ffffff'] }.to_h,
            },
            series: send(type, { bars: bars, types: keys }),
          }
        end,
      }
    end

    def stacked_data
      [
        data(
          '2020 Cohort',
          '2020_cohort',
          :stack,
          options: {},
        ),
        data(
          '2021 Cohort',
          '2021_cohort',
          :stack,
          options: {},
        ),
      ]
    end
  end
end
