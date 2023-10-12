module AllNeighborsSystemDashboard
  class UnhousedPopulation < DashboardData
    include AllNeighborsSystemDashboard::CensusCalculations
    def self.cache_data(report)
      instance = new(report)
      instance.donut_data
    end

    def data(title, id, type, options: {})
      keys = (options[:types] || []).map { |key| to_key(key) }
      identifier = "#{@report.cache_key}/#{cache_key(id, type, options)}/#{__method__}"
      existing = @report.datasets.find_by(identifier: identifier)
      return existing.data.with_indifferent_access if existing.present?

      data = {
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

      @report.datasets.create!(
        identifier: identifier,
        data: data,
      )
      data
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
      identifier = "#{@report.cache_key}/#{cache_key(id, type, options)}/#{__method__}"
      existing = @report.datasets.find_by(identifier: identifier)
      return existing.data.with_indifferent_access if existing.present?

      data = {
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
      @report.datasets.create!(
        identifier: identifier,
        data: data,
      )
      data
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
          bars: ['Unhoused Population *', 'Overall Population (Census 2020)'],
          demographic: :race,
          types: demographic_race,
          colors: demographic_race_colors,
        },
      )
    end

    def donut(options)
      options[:types].map do |project_type|
        {
          name: project_type,
          series: date_range.map do |date|
            scope = report_enrollments_enrollment_scope.
              distinct.
              select(:destination_client_id)
            scope = filter_for_type(scope, project_type)
            scope = filter_for_count_level(scope, 'Individuals')
            scope = filter_for_date(scope, date)
            count = bracket_small_population(scope.count, mask: @report.mask_small_populations?)
            {
              date: date.strftime('%Y-%-m-%-d'),
              values: Array.wrap(count),
            }
          end,
        }
      end
    end

    private def filter_for_date(scope, date)
      range = date.beginning_of_year .. date.end_of_year
      # Enrollment overlaps range
      where_clause = date_query(range)
      scope.where(where_clause)
    end

    private def date_query(range)
      en_t = Enrollment.arel_table
      en_t[:exit_date].gteq(range.first).or(en_t[:exit_date].eq(nil)).and(en_t[:entry_date].lteq(range.last))
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
        puts [date, demographic, bar, label].inspect
        raise "Unknown demographic category #{demographic}"
      end
    end

    def housing_status_values(date, label)
      scope = report_enrollments_enrollment_scope.
        distinct.
        select(:destination_client_id)
      scope = filter_for_count_level(scope, 'Individuals')
      scope = filter_for_date(scope, date)
      scope = case label
      when 'Safe Haven', 'Transitional Housing'
        scope.where(project_type: HudUtility2024.project_type(label, true))
      when 'Emergency Shelter'
        scope.where(project_type: [HudUtility2024.project_type('Emergency Shelter - Entry Exit', true), HudUtility2024.project_type('Emergency Shelter - Night-by-Night', true)])
      when 'Unsheltered'
        scope.where(project_type: HudUtility2024.project_type('Street Outreach', true))
      end
      count = bracket_small_population(scope.count, mask: @report.mask_small_populations?)
      count
    end

    def race_status_values(date, bar, label)
      population = bar.split.first
      scope = report_enrollments_enrollment_scope.
        distinct.
        select(:destination_client_id)
      scope = filter_for_count_level(scope, 'Individuals')
      scope = filter_for_date(scope, date)
      scope = case population
      when 'All'
        scope
      when 'Sheltered'
        scope.where.not(project_type: HudUtility2024.project_type('Street Outreach', true))
      when 'Unsheltered'
        scope.where(project_type: HudUtility2024.project_type('Street Outreach', true))
      else
        race_code = HudUtility2024.race(label, true)
        return get_us_census_population_by_race(race_code: race_code, year: date.year).to_i
      end
      scope = scope.where(primary_race: label)
      count = bracket_small_population(scope.count, mask: @report.mask_small_populations?)
      count
    end
  end
end
