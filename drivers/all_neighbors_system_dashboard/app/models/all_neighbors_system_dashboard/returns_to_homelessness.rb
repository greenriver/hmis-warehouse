module AllNeighborsSystemDashboard
  class ReturnsToHomelessness < DashboardData
    def self.cache_data(report)
      instance = new(report)
      instance.stacked_data
    end

    def data(title, id, type, options: {})
      keys = (options[:types] || []).map { |key| to_key(key) }
      Rails.cache.fetch("#{@report.cache_key}/#{cache_key(id, type, options)}/#{__method__}", expires_in: 1.years) do
        {
          title: title,
          id: id,
          demographics: demographics.map do |demo|
            bars = ['Exited*', 'Returned']
            demo_names_meth = "demographic_#{demo.gsub(' ', '').underscore}".to_sym
            demo_colors_meth = "demographic_#{demo.gsub(' ', '').underscore}_colors".to_sym
            names = send(demo_names_meth)
            keys = names.map { |key| to_key(key) }
            colors = send(demo_colors_meth)
            scope = enrollment_scope
            scope = filter_for_year(scope, Date.new(options[:year]))
            scope = filter_for_count_level(scope, 'Households')
            exited_household_count = scope.count
            returned_household_count = scope.where.not(return_date: nil).count
            {
              demographic: demo,
              config: {
                keys: keys,
                names: keys.map.with_index { |key, i| [key, names[i]] }.to_h,
                colors: keys.map.with_index { |key, i| [key, colors[i]] }.to_h,
                label_colors: keys.map.with_index { |key, i| [key, label_color(colors[i])] }.to_h,
              },
              series: send(type, { bars: bars, demographic: demo, types: names, year: options[:year] }),
              exited_household_count: exited_household_count,
              returned_household_count: returned_household_count,
            }
          end,
        }
      end
    end

    def stacked_data
      relevant_years.map do |year|
        cohort_name = "#{year} Cohort"

        data(
          cohort_name,
          to_key(cohort_name),
          :stack,
          options: { year: year },
        )
      end
    end

    def stack(options)
      project_type = options[:project_type]
      demographic = options[:demographic]
      bars = project_type.present? ? [project_type] + options[:bars] : options[:bars]
      bars.map do |bar|
        {
          name: bar,
          series: relevant_date_range.map do |date|
            next unless date.year == options[:year]

            {
              date: date.strftime('%Y-%-m-%-d'),
              values: options[:types].map { |label| stack_value(date, bar, demographic, label) },
            }
          end.compact,
        }
      end
    end

    # This tab is only relevant for years that completed over a year ago because it looks at returns within a year of exiting
    def relevant_date_range
      max_date = Date.current.beginning_of_year - 1.years
      # strictly less than the beginning of the prior year
      date_range.select { |date| date < max_date }
    end

    # This tab is only relevant for years that completed over a year ago because it looks at returns within a year of exiting
    def relevant_years
      max_year = (Date.current.beginning_of_year - 1.years).year
      # strictly less than the beginning of the prior year
      years.select { |year| year < max_year }
    end

    private def filter_for_date(scope, date)
      en_t = Enrollment.arel_table
      # NOTE: even though we aggregate at the year level, we calculate the month range and let JS do the aggregation
      range = date.beginning_of_month .. date.end_of_month
      where_clause = en_t[:exit_date].between(range).and(en_t[:exit_type].eq('Permanent'))
      scope.where(where_clause)
    end

    private def filter_for_year(scope, date)
      en_t = Enrollment.arel_table
      # NOTE: even though we aggregate at the year level, we calculate the month range and let JS do the aggregation
      range = date.beginning_of_year .. date.end_of_year
      where_clause = en_t[:exit_date].between(range).and(en_t[:exit_type].eq('Permanent'))
      scope.where(where_clause)
    end

    private def enrollment_scope
      report_enrollments_enrollment_scope.
        distinct.
        select(:destination_client_id)
    end

    def stack_value(date, bar, demographic, label)
      scope = enrollment_scope
      scope = filter_for_count_level(scope, 'Individuals')
      scope = filter_for_date(scope, date)

      scope = case bar
      when 'Exited*'
        scope.where(exit_type: 'Permanent')
      when 'Returned'
        scope.where(exit_type: 'Permanent').where.not(return_date: nil)
      end

      scope = case demographic
      when 'Race'
        scope.where(primary_race: label)
      when 'Age', 'Gender'
        filter_for_type(scope, label)
      when 'Household Type'
        scope.where(household_type: label)
      end
      scope.count
    end

    def bars
      # NOTE: not cached, but only a handful of queries
      cohort_keys = relevant_years.map { |year| "#{year} Cohort" }
      scope = enrollment_scope
      # NOTE: there is no picker on this page currently, but this could be updated if necessary
      scope = filter_for_count_level(scope, 'Individuals')
      exited_counts = {}
      returned_counts = {}
      # Make sure there are no missing years
      relevant_years.each do |year|
        start_of_year = Date.new(year)
        exited_scope = scope.where(exit_date: start_of_year..start_of_year.end_of_year)
        # NOTE: we filter return date on write and only add if the client returned within a year
        returned_scope = exited_scope.where.not(return_date: nil)

        exited_counts[year] = exited_scope.count
        returned_counts[year] = returned_scope.count
      end
      rates_of_return = returned_counts.values.zip(exited_counts.values).map do |returns, exits|
        rate = exits.zero? ? 0 : (returns.to_f / exits * 100).round(1)
        "#{rate}%"
      end
      {
        title: 'Returns to Homelessness',
        id: 'returns_to_homelessness',
        config: {
          colors: {
            exited: ['#336770', '#884D01'], # FIXME
            returned: ['#85A4A9', '#B48F5F'],
          },
          keys: cohort_keys,
        },
        series: [
          { name: 'exited', values: exited_counts.values },
          { name: 'returned', values: returned_counts.values },
          { name: 'rate', values: rates_of_return, table_only: true },
        ],
      }
    end
  end
end
