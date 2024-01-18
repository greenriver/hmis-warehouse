###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AllNeighborsSystemDashboard
  class FakeReturnsToHomelessness < FakeData
    def data(title, id, type, options: {})
      keys = (options[:types] || []).map { |key| to_key(key) }
      {
        title: title,
        id: id,
        demographics: demographics.map do |demo|
          bars = ['Exited', 'Returned']
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
              label_colors: keys.map.with_index { |key, i| [key, label_color(colors[i])] }.to_h,
            },
            series: send(type, { bars: bars, types: keys }),
            exited_household_count: 10,
            returned_household_count: 5,
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

    def bars
      rate_of_return = ['15.1%', '26.7%', '10%']
      {
        title: 'Returns to Homelessness',
        id: 'returns_to_homelessness',
        config: {
          colors: {
            exited: ['#336770', '#884D01', '#336770'],
            returned: ['#85A4A9', '#B48F5F', '#85A4A9'],
          },
          keys: ['2020 Cohort', '2021 Cohort', '2022 Cohort'],
        },
        series: [
          { name: 'exited', values: [821, 1141, 500] },
          { name: 'returned', values: [200, 275, 450] },
          { name: 'rate', values: rate_of_return, table_only: true },
        ],
      }
    end

    def internal_data(title, id, type, options: {})
      keys = (options[:types] || []).map { |key| to_key(key) }
      {
        title: title,
        id: id,
        quarters: quarter_range,
        project_types: project_types.map do |project_type|
          {
            project_type: project_type,
            count_levels: count_levels.map do |count_level|
              {
                count_level: count_level,
                cohorts: return_cohorts.map do |cohort|
                  {
                    cohort: cohort,
                    config: {
                      keys: keys,
                      names: keys.map.with_index { |key, i| [key, (options[:types])[i]] }.to_h,
                      colors: keys.map.with_index { |key, i| [key, options[:colors][i]] }.to_h,
                      label_colors: keys.map.with_index { |key, i| [key, label_color(options[:colors][i])] }.to_h,
                    },
                    series: send(type, options),
                  }
                end,
              }
            end,
          }
        end,
      }
    end

    def internal_vertical_stack
      internal_data(
        'Housing Retention',
        'housing_retention',
        :stack,
        options: {
          bars: quarter_range.map { |quarter| quarter[:name] },
          types: housing_retention_types,
          colors: housing_retention_type_colors,
        },
      )
    end

    def internal_bars(_options)
      totals = [rand(150..200), rand(300..500)]
      percentages = [rand(0..totals[0] - 100), rand(0..totals[1] - 100)]
      [
        { name: 'total', values: totals },
        { name: 'returned', values: percentages },
      ]
    end

    def horizontal_bars_data
      internal_data(
        'Returns to Homelessness To Date by HH Type',
        'returns_to_date_by_hh_type',
        :internal_bars,
        options: {
          types: demographic_household_type.reverse,
          colors: demographic_household_type_colors.reverse,
        },
      )
    end
  end
end
