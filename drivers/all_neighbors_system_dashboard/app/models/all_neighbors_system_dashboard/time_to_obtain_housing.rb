module AllNeighborsSystemDashboard
  class TimeToObtainHousing < FakeData
    def data(title, id, type, options: {})
      keys = (options[:types] || []).map { |key| to_key(key) }
      {
        title: title,
        id: id,
        project_types: project_types.map do |project_type|
          {
            project_type: project_type,
            config: {
              keys: keys,
              names: keys.map.with_index { |key, i| [key, (options[:types])[i]] }.to_h,
              colors: keys.map.with_index { |key, i| [key, options[:colors][i]] }.to_h,
              label_colors: keys.map.with_index { |key, i| [key, (options[:label_colors] || options[:colors])[i]] }.to_h,
            },
            household_types: (['All'] + household_types).map do |household_type|
              {
                household_type: household_type,
                demographics: demographics.map do |demo|
                  demo_names_meth = "demographic_#{demo.gsub(' ', '').underscore}".to_sym
                  filter_bars = demo_names_meth == :demographic_household_type && household_type != 'All'
                  demo_names = send(demo_names_meth)
                  demo_bars = filter_bars ? demo_names.select { |bar| bar == household_type } : demo_names
                  bars = (['Overall'] + demo_bars)
                  {
                    demographic: demo,
                    series: send(type, options.merge({ bars: bars })),
                  }
                end,
              }
            end,
          }
        end,
      }
    end

    def stacked_data
      return data(
        'Household Average Days from Identification to Housing by Race',
        'household_average_days',
        :stack,
        options: {
          types: ['ID to Referral', 'Referral to Move-in*'],
          colors: ['#336770', '#E6B70F'],
          label_colors: ['#ffffff', '#000000'],
        },
      )
    end
  end
end
