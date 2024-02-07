###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AllNeighborsSystemDashboard
  class FakeHousingTotalPlacementsData < FakeData
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
              if type == :line
                {
                  count_level: count_level,
                  series: send(type, opts),
                  monthly_counts: send(type, opts.merge({ range: [100, 500] })),
                }
              elsif type == :line_data_by_quarter
                {
                  count_level: count_level,
                  program_names: internal_data(type, opts),
                }
              else
                {
                  count_level: count_level,
                  series: send(type, opts),
                }
              end
            end,
          }
        end,
      }
    end

    def internal_data(_, opts)
      program_names.map do |name|
        {
          program_name: name,
          populations: populations.map do |pop|
            {
              population: pop,
              count_types: count_types.map do |count_type|
                {
                  count_type: count_type,
                  series: send(:line, opts),
                  monthly_counts: send(:line, opts.merge({ range: [100, 500] })),
                  breakdown_counts: [count_breakdowns],
                }
              end,
            }
          end,
        }
      end
    end

    def count_breakdowns
      quarter_range.map do |date|
        breakdown = [
          { label: 'New General Household Placed', value: 71 },
          { label: 'New DV Household Placed', value: 1 },
          { label: 'Total New Households Placed', value: 72 },
          { label: 'General Population Households Placed to Date', value: 836 },
          { label: 'DV Population Households Placed to Date', value: 82 },
        ]
        [date[:range][0], breakdown]
      end
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

    def line_data_by_quarter
      data(
        'Total Placements',
        'total_placements',
        :line_data_by_quarter,
        options: {
          types: ['Total Placements'],
          colors: ['#832C5A'],
          label_colors: ['#000000'],
          by_quarter: true,
        },
      )
    end

    def line(options)
      if options[:by_quarter]
        project_type = options[:project_type]
        types = options[:types] || []
        types = types.select { |t| t == project_type } if options[:by_project_type] && project_type != 'All'
        types.map.with_index do |_d, i|
          base = 100
          super(quarter_range, options.merge(range: [i * base, (i + 1) * base]))
        end
      else
        (options[:types] || []).map do |_|
          super(date_range, options)
        end
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
