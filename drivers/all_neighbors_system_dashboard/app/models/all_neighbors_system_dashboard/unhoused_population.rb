module AllNeighborsSystemDashboard
  class UnhousedPopulation < DashboardData
    def self.cache_data(report)
      instance = new(report)
      instance.donut_data
    end

    def initialize(...)
      super
      @enrollments_in_range ||= {}
    end

    def data(title, id, type, options: {})
      keys = (options[:types] || []).map { |key| to_key(key) }
      Rails.cache.fetch("#{@report.cache_key}/#{cache_key(id, type, options)}/#{__method__}") do
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
    end

    def vertical_stack
      data(
        'People Experiencing Homelessness',
        'people_experiencing_homelessness',
        :stack,
        options: { bars: years, demographic: :homelessness_type, types: homeless_population_types },
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
            data_set: :homelessness_status,
            types: homelessness_statuses.reject { |type| type == 'All' },
            colors: homelessness_status_colors,
          },
        ),
        homelessness_status_data(
          'Household Type',
          'household_type',
          :donut,
          options: {
            data_set: :household_type,
            types: household_types,
            colors: household_type_colors,
          },
        ),
        homelessness_status_data(
          'Age',
          'age',
          :donut,
          options: {
            data_set: :age,
            types: demographic_age,
            colors: demographic_age_colors,
          },
        ),
        homelessness_status_data(
          'Gender',
          'gender',
          :donut,
          options: {
            data_set: :gender,
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
          bars: ['Unhoused Population *'], # TODO:, 'Overall Population (Census 2020)'],
          demographic: :race,
          types: demographic_race,
          colors: demographic_race_colors,
        },
      )
    end

    def donut(options)
      options[:types].map do |type|
        {
          name: type,
          series: date_range.map do |date|
            {
              date: date.strftime('%Y-%-m-%-d'),
              values: Array.wrap(donut_value(date, type, options)),
            }
          end,
        }
      end
    end

    def donut_value(date, label, options)
      # {:data_set=>:homelessness_status,
      #  :types=>["Sheltered", "Unsheltered"],
      #  :colors=>["#B2803F", "#1865AB"],
      #  :homelessness_status=>"All"}
      data_set = options[:data_set]
      enrollments = case data_set
      when :homelessness_status
        if label == 'Unsheltered'
          enrollments_in_range(date).select { |enrollment| enrollment.project_type == HudUtility2024.project_type('Street Outreach', true) }
        else
          enrollments_in_range(date).reject { |enrollment| enrollment.project_type == HudUtility2024.project_type('Street Outreach', true) }
        end
      when :household_type
        enrollments_in_range(date).select { |enrollment| enrollment.household_type == label }
      when :age
        case label
        when 'Under 18'
          enrollments_in_range(date).select { |enrollment| enrollment.age.present? && enrollment.age < 18 }
        when '18 to 24'
          enrollments_in_range(date).select { |enrollment| enrollment.age.present? && enrollment.age.between?(18, 24) }
        when '25 to 39'
          enrollments_in_range(date).select { |enrollment| enrollment.age.present? && enrollment.age.between?(25, 39) }
        when '40 to 49'
          enrollments_in_range(date).select { |enrollment| enrollment.age.present? && enrollment.age.between?(40, 49) }
        when '50 to 62'
          enrollments_in_range(date).select { |enrollment| enrollment.age.present? && enrollment.age.between?(50, 62) }
        when 'Over 63'
          enrollments_in_range(date).select { |enrollment| enrollment.age.present? && enrollment.age >= 63 }
        when 'Unknown Age'
          enrollments_in_range(date).select { |enrollment| enrollment.age.blank? }
        end
      when :gender
        if label == 'Unknown Gender'
          enrollments_in_range(date).select { |enrollment| enrollment.gender.blank? || enrollment.gender.in?(unknown_genders) }
        else
          enrollments_in_range(date).select { |enrollment| enrollment.gender.present? && enrollment.gender == label }
        end
      end
      enrollments.count
    end

    def stack(options)
      project_type = options[:project_type]
      homelessness_status = options[:homelessness_status]
      demographic = options[:demographic]
      bars = project_type.present? ? [project_type] + options[:bars] : options[:bars]
      bars[0] = "#{homelessness_status} #{bars[0]}" if homelessness_status.present?
      bars.map do |bar|
        {
          name: bar,
          series: date_range.map do |date|
            {
              date: date.strftime('%Y-%-m-%-d'),
              values: options[:types].map { |label| stack_value(date, demographic, bar, label) },
            }
          end,
        }
      end
    end

    def stack_value(date, demographic, bar, label)
      case demographic
      when :homelessness_type
        housing_status_values(date, label)
      when :race
        race_status_values(date, bar, label)
      else
        10
      end
    end

    def enrollments_in_range(date)
      year_range = date.beginning_of_year .. date.end_of_year
      @enrollments_in_range[year_range] ||= @report.enrollment_data.select { |enrollment| ranges_overlap?(year_range, enrollment.entry_date .. (enrollment.exit_date || Date.current)) }
    end

    def housing_status_values(date, label)
      enrollments = case label
      when 'Safe Haven'
        enrollments_in_range(date).select { |enrollment| enrollment.project_type == HudUtility2024.project_type('Safe Haven', true) }
      when 'Transitional Housing'
        enrollments_in_range(date).select { |enrollment| enrollment.project_type == HudUtility2024.project_type('Transitional Housing', true) }
      when 'Emergency Shelter'
        enrollments_in_range(date).select do |enrollment|
          enrollment.project_type.in?(
            [
              HudUtility2024.project_type('Emergency Shelter - Entry Exit', true),
              HudUtility2024.project_type('Emergency Shelter - Night-by-Night', true),
            ],
          )
        end
      when 'Unsheltered'
        enrollments_in_range(date).select { |enrollment| enrollment.project_type == HudUtility2024.project_type('Street Outreach', true) }
      end
      enrollments.count
    end

    def race_status_values(date, bar, label)
      population = bar.split.first
      subpopulation = case population
      when 'All'
        enrollments_in_range(date)
      when 'Sheltered'
        enrollments_in_range(date).reject { |enrollment| enrollment.project_type == HudUtility2024.project_type('Street Outreach', true) }
      when 'Unsheltered'
        enrollments_in_range(date).select { |enrollment| enrollment.project_type == HudUtility2024.project_type('Street Outreach', true) }
      when 'Overall'
        # TODO Census data
      end
      subpopulation.select { |enrollment| enrollment.primary_race.present? && to_key(enrollment.primary_race) == label }.count
    end
  end
end
