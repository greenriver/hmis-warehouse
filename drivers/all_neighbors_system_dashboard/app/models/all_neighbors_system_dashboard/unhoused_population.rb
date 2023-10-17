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
            hide_others_when_not_all: true,
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
        :race_stack,
        options: {
          bars: ['Unhoused Population', 'Overall Population (Census)'],
          demographic: :race,
          types: demographic_race,
          colors: demographic_race_colors,
        },
      )
    end

    def donut(options)
      project_type = options[:project_type] || options[:homelessness_status]
      options[:types].map do |type|
        {
          name: type,
          series: date_range.map do |date|
            scope = report_enrollments_enrollment_scope.
              distinct.
              select(:destination_client_id)
            scope = filter_for_type(scope, project_type)
            scope = filter_for_type(scope, type)
            # NOTE: there is no filter for households right now, but it could be added here
            scope = filter_for_count_level(scope, 'Individuals')
            scope = filter_for_date(scope, date)
            count = mask_small_populations(scope.count, mask: @report.mask_small_populations?)
            count = options[:hide_others_when_not_all] && project_type != 'All' && type != project_type ? 0 : count
            {
              date: date.strftime('%Y-%-m-%-d'),
              values: Array.wrap(count),
            }
          end,
        }
      end
    end

    private def filter_for_date(scope, date)
      start_date = [date.beginning_of_year, @report.filter.start_date].max
      end_date = [date.end_of_year, @report.filter.end_date].min
      range = start_date .. end_date
      # Enrollment overlaps range
      where_clause = date_query(range)
      scope.where(where_clause)
    end

    private def date_query(range)
      en_t = Enrollment.arel_table
      en_t[:exit_date].gteq(range.first).or(en_t[:exit_date].eq(nil)).and(en_t[:entry_date].lteq(range.last))
    end

    # Unhoused is currently calculated on a yearly basis
    def date_range
      date_range = []
      current_date = @start_date
      while current_date <= @end_date
        date_range.push(current_date)
        current_date += 1.years
      end
      date_range
    end

    def stack(options)
      project_type = options[:project_type]
      # homelessness_status = options[:homelessness_status]
      bars = project_type.present? ? [project_type] + options[:bars] : options[:bars]
      bars.map do |bar|
        relevant_dates = date_range.select { |d| d.year == bar }
        {
          name: bar,
          series: relevant_dates.map do |date|
            {
              date: date.strftime('%Y-%-m-%-d'),
              values: options[:types].map { |label| housing_status_values(date, label) },
            }
          end,
        }
      end
    end

    def race_stack(options)
      homelessness_status = options[:homelessness_status]
      bars = options[:bars]
      bars[0] = homelessness_status unless homelessness_status == 'All'
      bars.map do |bar|
        relevant_dates = date_range

        {
          name: bar,
          series: relevant_dates.map do |date|
            {
              date: date.strftime('%Y-%-m-%-d'),
              values: options[:types].map { |label| race_status_values(date, bar, label, homelessness_status) },
            }
          end,
        }
      end
    end

    def housing_status_values(date, label)
      scope = report_enrollments_enrollment_scope.
        distinct.
        select(:destination_client_id)
      scope = filter_for_count_level(scope, 'Individuals')
      # this entire set is limited to unhoused clients
      scope = scope.where(project_type: HudUtility2024.homeless_project_type_numbers)
      scope = case label
      when 'Safe Haven', 'Transitional Housing'
        scope.where(project_type: HudUtility2024.project_type(label, true))
      when 'Emergency Shelter'
        scope.where(project_type: [HudUtility2024.project_type('Emergency Shelter - Entry Exit', true), HudUtility2024.project_type('Emergency Shelter - Night-by-Night', true)])
      when 'Unsheltered'
        scope.where(project_type: HudUtility2024.project_type('Street Outreach', true))
      end

      scope = filter_for_date(scope, date)
      count = mask_small_populations(scope.distinct.select(:destination_client_id).count, mask: @report.mask_small_populations?)

      count
    end

    def race_status_values(date, bar, label, status)
      if bar.include?('Census')
        race_code = HudUtility2024.race(label, true)
        return get_us_census_population_by_race(race_code: race_code, year: date.year).to_i
      end

      scope = report_enrollments_enrollment_scope.
        distinct.
        select(:destination_client_id)
      scope = filter_for_count_level(scope, 'Individuals')
      scope = filter_for_date(scope, date)
      # this entire set is limited to unhoused clients
      scope = scope.where(project_type: HudUtility2024.homeless_project_type_numbers)

      scope = case status
      when 'Unsheltered'
        scope.where(project_type: HudUtility2024.project_type('Street Outreach', true))
      when 'Sheltered'
        scope.where.not(project_type: HudUtility2024.project_type('Street Outreach', true))
      else
        scope
      end
      scope = scope.where(primary_race: label)
      count = mask_small_populations(scope.count, mask: @report.mask_small_populations?)

      count
    end
  end
end
