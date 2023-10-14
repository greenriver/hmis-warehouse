module AllNeighborsSystemDashboard
  class HousingTotalPlacementsData < DashboardData
    include AllNeighborsSystemDashboard::CensusCalculations

    def self.cache_data(report)
      instance = new(report)
      instance.data('Total Placements', 'total_placements', :line)
      instance.donut_data
      instance.stacked_data
    end

    def data(title, id, type, options: {})
      keys = (options[:types] || []).map { |key| to_key(key) }
      identifier = "#{@report.cache_key}/#{cache_key(id, type, options)}/#{__method__}"
      existing = @report.datasets.find_by(identifier: identifier)
      return existing.data.with_indifferent_access if existing.present?

      data = {
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
              monthly_counts = send(type, options.merge(project_type: project_type, count_level: count_level))

              if type == :line
                summary_counts = aggregate(monthly_counts)
                {
                  count_level: count_level,
                  series: [summary_counts],
                  monthly_counts: [monthly_counts],
                }
              else
                {
                  count_level: count_level,
                  series: monthly_counts,
                }
              end
            end,
          }
        end,
      }

      @report.datasets.create!(
        identifier: identifier,
        data: data,
      )
      data
    end

    private def aggregate(series)
      total_count = 0
      series.map do |date, counts|
        total_count += counts
        [
          date,
          total_count,
        ]
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
        count = bracket_small_population(scope.count, mask: @report.mask_small_populations?)
        [
          date.strftime('%Y-%-m-%-d'),
          count,
        ]
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

    private def filter_for_date(scope, date)
      range = date.beginning_of_month .. date.end_of_month
      where_clause = date_query(range)
      scope.where(where_clause)
    end

    private def date_query(range)
      en_t = Enrollment.arel_table
      en_t[:exit_type].eq('Permanent').and(en_t[:exit_date].between(range)).
        or(en_t[:move_in_date].between(range))
    end

    # Example format of options: {:types=>["Diversion", "Permanent Supportive Housing", "Rapid Rehousing"], :colors=>["#E6B70F", "#B2803F", "#1865AB"], :project_type=>"All", :count_level=>"Individuals"}
    def donut(options)
      project_type = options[:project_type] || options[:homelessness_status]
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
            count = bracket_small_population(scope.count, mask: @report.mask_small_populations?)
            count = options[:hide_others_when_not_all] && project_type != 'All' && type != project_type ? 0 : count
            {
              date: date.strftime('%Y-%-m-%-d'),
              values: [count],
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
            hide_others_when_not_all: true,
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
            counts = options[:types].map do |race_name|
              race_code = HudUtility2024.race(race_name, true)
              scope = report_enrollments_enrollment_scope.
                housed.
                distinct.
                select(:destination_client_id)
              scope = filter_for_count_level(scope, options[:count_level])
              scope = filter_for_date(scope, date)
              scope = scope.where(primary_race: race_name)
              case bar
              when 'Overall Population (Census)'
                get_us_census_population_by_race(race_code: race_code, year: date.year).to_i
              when 'All'
                count = bracket_small_population(scope.count, mask: @report.mask_small_populations?)
                count
              else
                scope = filter_for_type(scope, bar)
                count = bracket_small_population(scope.count, mask: @report.mask_small_populations?)
                count
              end
            end
            {
              date: date.strftime('%Y-%-m-%-d'),
              values: counts,
            }
          end,
        }
      end.compact
    end

    def stacked_data
      return data(
        'Racial Composition',
        'racial_composition',
        :stack,
        options: {
          bars: ['Unhoused Population', 'Overall Population (Census)'],
          types: demographic_race,
          colors: demographic_race_colors,
          label_colors: demographic_race.map { |_| '#ffffff' },
        },
      )
    end
  end
end
