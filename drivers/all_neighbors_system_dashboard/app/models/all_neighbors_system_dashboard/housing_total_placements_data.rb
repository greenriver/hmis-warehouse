module AllNeighborsSystemDashboard
  class HousingTotalPlacementsData < FakeData
    def data(title, id, type, options: {})
      keys = (options[:types] || []).map { |key| to_key(key) }
      {
        title: title,
        id: id,
        quarters: quarter_range,
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
              opts = options[:include_project_type] ? options.merge(project_type: project_type) : options
              {
                count_level: count_level,
                series: send(type, opts),
              }
            end,
          }
        end,
      }
    end

    def line_data
      data(
        'Total Placements',
        'total_placements',
        :line,
        options: {
          types: ['Total Placements'],
          colors: ['#832C5A'],
          label_colors: ['#000000'],
        },
      )
    end

    def line(options)
      (options[:types] || []).map do |_|
        super(date_range, options)
      end
    end

    def donut_data
      [
        data(
          'Project Type',
          'project_type',
          :donut,
          options: {
            include_project_type: true,
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
          include_project_type: true,
          bars: ['Unhoused Population 2023 *', 'Overall Population (Census 2020)'],
          types: demographic_race,
          colors: demographic_race_colors,
          label_colors: demographic_race.map { |_| '#ffffff' },
        },
      )
    end

    def internal_stacked_data
      return data(
        'Racial Composition',
        'racial_composition',
        :stack,
        options: {
          bars: [
            'Homeless Services',
            'Coordinated Access System',
            'Rapid Rehousing',
            'Emergency Housing Voucher',
            'Unhoused Population 2023 *',
            'Overall Population (Census 2020)',
          ],
          types: demographic_race,
          colors: demographic_race_colors,
          label_colors: demographic_race.map { |_| '#ffffff' },
        },
      )
    end
  end
end
