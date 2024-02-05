###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AllNeighborsSystemDashboard
  class FakeUnhousedPopulation < FakeData
    def data(title, id, type, options: {})
      keys = (options[:types] || []).map { |key| to_key(key) }
      {
        title: title,
        id: id,
        series: send(type, options),
        config: {
          keys: keys,
          names: keys.map.with_index { |key, i| [key, options[:types][i]] }.to_h,
          colors: keys.map.with_index { |key, i| [key, homeless_population_type_colors[i]] }.to_h,
          label_colors: keys.map.with_index { |key, i| [key, label_color(homeless_population_type_colors[i])] }.to_h,
        },
      }
    end

    def vertical_stack
      data(
        'People Experiencing Homelessness',
        'people_experiencing_homelessness',
        :stack,
        options: { bars: year_range.map { |date| date.strftime('%Y') }, types: homeless_population_types },
      )
    end

    def homelessness_status_data(title, id, type, options: {})
      keys = (options[:types] || []).map { |key| to_key(key) }
      {
        title: title,
        id: id,
        homelessness_statuses: homelessness_statuses.map do |status|
          {
            homelessness_status: status,
            config: {
              keys: keys,
              names: keys.map.with_index { |key, i| [key, (options[:types])[i]] }.to_h,
              colors: keys.map.with_index { |key, i| [key, options[:colors][i]] }.to_h,
              label_colors: keys.map.with_index { |key, i| [key, label_color(options[:colors][i])] }.to_h,
            },
            series: send(type, options.merge(homelessness_status: status)),
          }
        end,
      }
    end

    def donut_data
      [
        homelessness_status_data(
          'Homelessness Status',
          'homelessness_status',
          :donut,
          options: {
            fake_data: true,
            types: homelessness_statuses.reject { |type| type == 'All' },
            colors: homelessness_status_colors,
          },
        ),
        homelessness_status_data(
          'Household Type',
          'household_type',
          :donut,
          options: {
            types: household_types,
            colors: household_type_colors,
          },
        ),
        homelessness_status_data(
          'Age',
          'age',
          :donut,
          options: {
            types: demographic_age,
            colors: demographic_age_colors,
          },
        ),
        homelessness_status_data(
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
      return homelessness_status_data(
        'Racial Composition',
        'racial_composition',
        :stack,
        options: {
          bars: ['Unhoused Population *', 'Overall Population (Census 2020)'],
          types: demographic_race,
          colors: demographic_race_colors,
        },
      )
    end
  end
end
