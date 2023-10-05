module AllNeighborsSystemDashboard
  class ReturnsToHomelessness < DashboardData
    def initialize(...)
      super
      @enrollments_in_range ||= {}
    end

    def self.cache_data(report)
      instance = new(report)
      instance.stacked_data
    end

    def data(title, id, type, options: {})
      keys = (options[:types] || []).map { |key| to_key(key) }
      Rails.cache.fetch("#{@report.cache_key}/#{cache_key(id, type, options)}/#{__method__}", expires_in: 1.hour) do
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
            {
              demographic: demo,
              config: {
                keys: keys,
                names: keys.map.with_index { |key, i| [key, names[i]] }.to_h,
                colors: keys.map.with_index { |key, i| [key, colors[i]] }.to_h,
                label_colors: keys.map.with_index { |key, i| [key, label_color(colors[i])] }.to_h,
              },
              series: send(type, { bars: bars, demographic: demo, types: keys }),
            }
          end,
        }
      end
    end

    def stacked_data
      years.map do |year|
        cohort_name = "#{year} Cohort"

        data(
          cohort_name,
          to_key(cohort_name),
          :stack,
          options: {},
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
          series: date_range.map do |date|
            {
              date: date.strftime('%Y-%-m-%-d'),
              values: options[:types].map { |label| stack_value(date, bar, demographic, label) },
            }
          end,
        }
      end
    end

    def stack_value(date, bar, demographic, label)
      year_range = date.beginning_of_year .. date.end_of_year
      enrollments_in_range = @enrollments_in_range[year_range] ||= @report.enrollment_data.select { |enrollment| enrollment.exit_date.present? && date.in?(year_range) }
      enrollments = case bar
      when 'Exited*'
        enrollments_in_range.select { |enrollment| enrollment.exit_type == 'Permanent' }
      when 'Returned'
        enrollments_in_range.select { |enrollment| enrollment.exit_type == 'Permanent' && enrollment.return_date.present? }
      end
      case demographic
      when 'Race'
        enrollments.select { |enrollment| enrollment.primary_race.present? && to_key(enrollment.primary_race) == label }.count
      when 'Age'
        case label
        when 'Under_18'
          enrollments.select { |enrollment| enrollment.age.present? && enrollment.age < 18 }.count
        when '18_to_24'
          enrollments.select { |enrollment| enrollment.age.present? && enrollment.age.between?(18, 24) }.count
        when '25_to_39'
          enrollments.select { |enrollment| enrollment.age.present? && enrollment.age.between?(25, 39) }.count
        when '40_to_49'
          enrollments.select { |enrollment| enrollment.age.present? && enrollment.age.between?(40, 49) }.count
        when '50_to_62'
          enrollments.select { |enrollment| enrollment.age.present? && enrollment.age.between?(50, 62) }.count
        when 'Over_63'
          enrollments.select { |enrollment| enrollment.age.present? && enrollment.age >= 63 }.count
        when 'Unknown Age'
          enrollments.select { |enrollment| enrollment.age.blank? }.count
        end
      when 'Gender'
        if label == 'Unknown Gender'
          enrollments.select { |enrollment| enrollment.gender.blank? || enrollment.gender.in?(unknown_genders) }.count
        else
          enrollments.select { |enrollment| enrollment.gender.present? && to_key(enrollment.gender) == label }.count
        end
      when 'Household Type'
        enrollments.select { |enrollment| to_key(enrollment.household_type) == label }.count
      end
    end

    def bars
      cohort_keys = years.map { |year| "#{year} Cohort" }
      exited_enrollments = @report.enrollment_data.select { |enrollment| enrollment.exit_type == 'Permanent' }
      exited_counts = exited_enrollments.group_by { |enrollment| enrollment.exit_date.year }.transform_values!(&:count)
      returned_enrollments = exited_enrollments.select { |enrollment| enrollment.return_date.present? && enrollment.return_date <= enrollment.exit_date + 1.year }
      returned_counts = returned_enrollments.group_by { |enrollment| enrollment.exit_date.year }.transform_values!(&:count)
      # Make sure there are no missing years
      years.each do |key|
        exited_counts[key] ||= 0
        returned_counts[key] ||= 0
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
