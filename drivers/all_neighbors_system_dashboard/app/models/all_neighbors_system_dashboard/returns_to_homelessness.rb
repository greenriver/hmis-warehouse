###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AllNeighborsSystemDashboard
  class ReturnsToHomelessness < DashboardData
    def self.cache_data(report)
      instance = new(report)
      instance.retuns_data
    end

    # Date should be the first of the month, range will extend through the month
    def clients_for_date(date:, count_level:, project_type:)
      count_item = count_one_client_per_date_arel
      scope = returned_total_scope
      scope = filter_for_type(scope, project_type)
      scope = filter_for_count_level(scope, count_level)
      scope = filter_for_date(scope, date)
      scope.pluck(count_item)
    end

    def project_types_with_data
      # FIXME: needs to be based on the data available
      project_types
      # raise 'hi'
      # @project_types_with_data ||= line_data[:project_types].
      #   # Reject any project types where we have NO data
      #   reject { |m| m[:count_levels].flatten.map { |n| n[:monthly_counts] }.flatten(2).map(&:last)&.all?(0) }.
      #   map { |m| m[:project_type] }
    end

    # Count once per client per day
    # NOTE: the enrollments table will never have more than one enrollment
    # per client per day
    private def count_one_client_per_date_arel
      nf(
        'concat',
        [
          Enrollment.arel_table[:destination_client_id],
          ' ',
          Enrollment.arel_table[:placed_date],
        ],
      )
    end

    def data(title, id, type, options: {})
      keys = (options[:types] || []).map { |key| to_key(key) }
      identifier = "#{@report.cache_key}/#{cache_key(id, type, options)}/#{__method__}"
      existing = @report.datasets.find_by(identifier: identifier)
      return existing.data.with_indifferent_access if existing.present?

      project_type_data = project_types.map do |project_type|
        count_level_data = count_levels.map do |count_level|
          case type
          when :retuns
            monthly_counts = retuns(
              options.merge(project_type: project_type, count_level: count_level),
              # Count clients only once per-day
              count_item: count_one_client_per_date_arel.to_sql,
            )
          else
            raise "Unknown type: #{type}"
          end
          {
            count_level: count_level,
            series: monthly_counts,
          }
        end

        {
          project_type: project_type,
          config: {
            keys: keys,
            names: keys.map.with_index { |key, i| [key, (options[:types])[i]] }.to_h,
            colors: keys.map.with_index { |key, i| [key, options[:colors][i]] }.to_h,
            label_colors: keys.map.with_index { |key, i| [key, label_color(options[:colors][i])] }.to_h,
          },
          count_levels: count_level_data,
        }
      end

      data = {
        title: title,
        id: id,
        project_types: project_type_data,
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

    private def filter_for_date(scope, date, start_date: date.beginning_of_month)
      range = start_date .. date.end_of_month
      scope.placed_in_range(range)
    end

    # Example format of options: {:types=>["Diversion", "Permanent Supportive Housing", "Rapid Rehousing"], :colors=>["#E6B70F", "#B2803F", "#1865AB"], :project_type=>"All", :count_level=>"Individuals"}
    def retuns(options, count_item:, **)
      project_type = options[:project_type] || options[:homelessness_status]
      options[:types].map do |type|
        {
          name: type,
          series: date_range.map do |date|
            # FIXME: this needs to calculate and return both returns and exits
            scope = returned_total_scope.select(count_item)
            scope = filter_for_type(scope, project_type)
            scope = filter_for_type(scope, type)
            scope = filter_for_count_level(scope, options[:count_level])
            scope = filter_for_date(scope, date)
            count = mask_small_populations(scope.count, mask: @report.mask_small_populations?)
            count = options[:hide_others_when_not_all] && project_type != 'All' && type != project_type ? 0 : count
            {
              date: date.strftime('%Y-%-m-%-d'),
              values: [count],
            }
          end,
        }
      end
    end

    def retuns_data
      [
        data(
          'Project Type',
          'project_type',
          :retuns,
          options: {
            hide_others_when_not_all: true,
            types: project_types,
            colors: project_type_colors,
          },
        ),
        data(
          'Household Type',
          'household_type',
          :retuns,
          options: {
            types: household_types,
            colors: household_type_colors,
          },
        ),
        data(
          'Age',
          'age',
          :retuns,
          options: {
            types: demographic_age,
            colors: demographic_age_colors,
          },
        ),
        data(
          'Gender',
          'gender',
          :retuns,
          options: {
            types: demographic_gender,
            colors: demographic_gender_colors,
          },
        ),
      ]
    end
  end
end
