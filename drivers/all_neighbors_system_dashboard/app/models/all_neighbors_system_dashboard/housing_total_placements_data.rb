module AllNeighborsSystemDashboard
  class HousingTotalPlacementsData < FakeData
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
            count_levels: count_levels.map do |count_level|
              {
                count_level: count_level,
                series: send(type, options.merge(project_type: project_type)),
              }
            end,
          }
        end,
      }
    end

    def line(_options)
      date_range.map { |date| [date.strftime('%Y-%-m-%-d'), rand(10..1500)] }
    end

    def donut(options)
      project_type = options[:project_type]
      options[:types].map do |type|
        value = options[:fake_data] && project_type != 'All' && type != project_type ? 0 : rand(10..1500)
        {
          name: type,
          series: date_range.map do |date|
            {
              date: date,
              values: [value],
            }
          end,
        }
      end
    end

    def donut_data
      [
        data(
          'Project Type',
          'project_type',
          :donut,
          options: {
            fake_data: true,
            types: project_types.reject { |type| type == 'All' },
            colors: project_type_colors,
          },
        ),
        data(
          'Household Type',
          'household_type',
          :donut,
          options: {
            types: household_types,
            colors: household_type_colors,
          },
        ),
        data(
          'Age',
          'age',
          :donut,
          options: {
            types: demographic_age,
            colors: demographic_age_colors,
          },
        ),
        data(
          'Gender',
          'gender',
          :donut,
          options: {
            types: demographic_gender,
            colors: demographic_gender_colors,
          },
        ),
      ]
    end

    def stacked_data
      return data(
        'Racial Composition',
        'racial_composition',
        :stack,
        options: {
          bars: ['Unhoused Population 2023 *', 'Overall Population (Census 2020)'],
          types: demographic_race,
          colors: demographic_race_colors,
        },
      )
    end
  end
end
