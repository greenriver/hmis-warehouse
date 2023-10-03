module AllNeighborsSystemDashboard
  class HousingTotalPlacementsData < DashboardData
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
              label_colors: keys.map.with_index { |key, i| [key, label_color(options[:colors][i])] }.to_h,
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
      # raise options.inspect
      # {:project_type=>"All"}
      date_range.map do |date|
        [
          date.strftime('%Y-%-m-%-d'),
          1_500,
        ]
      end # FIXME
    end

    def donut(options)
      project_type = options[:project_type] || options[:homelessness_status]
      options[:types].map do |type|
        # FIXME
        value = options[:fake_data] && project_type != 'All' && type != project_type ? 0 : 1_500 # FIXME
        {
          name: type,
          series: date_range.map do |date|
            {
              date: date.strftime('%Y-%-m-%-d'),
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

    def stack(options)
      project_type = options[:project_type]
      homelessness_status = options[:homelessness_status]
      bars = project_type.present? ? [project_type] + options[:bars] : options[:bars]
      bars[0] = "#{homelessness_status} #{bars[0]}" if homelessness_status.present?
      bars.map do |bar|
        {
          name: bar,
          series: date_range.map do |date|
            {
              date: date.strftime('%Y-%-m-%-d'),
              values: options[:types].map { |_| 1_500 }, # FIXME
            }
          end,
        }
      end
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
          label_colors: demographic_race.map { |_| '#ffffff' },
        },
      )
    end
  end
end
