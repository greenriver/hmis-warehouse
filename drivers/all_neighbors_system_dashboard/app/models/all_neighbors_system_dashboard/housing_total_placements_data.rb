module AllNeighborsSystemDashboard
  class HousingTotalPlacementsData < DashboardData
    def self.cache_data(report)
      instance = new(report)
      instance.data('Total Placements', 'total_placements', :line)
      instance.donut_data
      instance.stacked_data
    end

    def data(title, id, type, options: {})
      keys = (options[:types] || []).map { |key| to_key(key) }
      Rails.cache.fetch("#{@report.cache_key}/#{cache_key(id, type, options)}/#{__method__}", expires_in: 1.years) do
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
                  series: send(type, options.merge(project_type: project_type, count_level: count_level)),
                }
              end,
            }
          end,
        }
      end
    end

    def line(options)
      date_range.map do |date|
        scope = report_enrollments_enrollment_scope.
          housed.
          distinct.
          select(:destination_client_id)
        scope = filter_for_type(scope, options[:project_type])
        scope = filter_for_count_level(scope, options[:count_level])
        scope = filter_for_date(scope, date)
        [
          date.strftime('%Y-%-m-%-d'),
          scope.count,
        ]
      end # FIXME
    end

    private def filter_for_date(scope, date)
      en_t = Enrollment.arel_table
      range = date.beginning_of_month .. date.end_of_month
      where_clause = en_t[:exit_type].eq('Permanent').and(en_t[:exit_date].between(range)).
        or(en_t[:move_in_date].between(range))
      scope.where(where_clause)
    end

    def donut(options)
      project_type = options[:project_type] || options[:homelessness_status]
      # {:types=>["Diversion", "Permanent Supportive Housing", "Rapid Rehousing"], :colors=>["#E6B70F", "#B2803F", "#1865AB"], :project_type=>"All", :count_level=>"Individuals"}
      Rails.logger.info("TTTTTTT: #{options}")
      options[:types].map do |type|
        {
          name: type,
          series: date_range.map do |date|
            scope = report_enrollments_enrollment_scope.
              housed.
              distinct.
              select(:destination_client_id)
            scope = filter_for_type(scope, project_type)
            scope = filter_for_type(scope, type)
            scope = filter_for_count_level(scope, options[:count_level])
            scope = filter_for_date(scope, date)
            {
              date: date.strftime('%Y-%-m-%-d'),
              values: [scope.count],
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
