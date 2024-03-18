###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AllNeighborsSystemDashboard
  class ReturnsToHomelessness < DashboardData
    def self.cache_data(report)
      instance = new(report)
      instance.stacked_data
    end

    # Date should be the first of the month, range will extend through the month
    def clients_for_date(date:, count_level:, project_type:)
      count_item = count_one_client_per_date_arel
      scope = housed_total_scope
      scope = filter_for_type(scope, project_type)
      scope = filter_for_count_level(scope, count_level)
      scope = filter_for_date(scope, date)
      scope.pluck(count_item)
    end

    def project_types_with_data
      # @project_types_with_data ||= line_data[:project_types].
      #   # Reject any project types where we have NO data
      #   reject { |m| m[:count_levels].flatten.map { |n| n[:monthly_counts] }.flatten(2).map(&:last)&.all?(0) }.
      #   map { |m| m[:project_type] }
    end

    def data(title, id, type, options: {})
      keys = (options[:types] || []).map { |key| to_key(key) }
      identifier = "#{@report.cache_key}/#{cache_key(id, type, options)}/#{__method__}"
      existing = @report.datasets.find_by(identifier: identifier)
      return existing.data.with_indifferent_access if existing.present?


      project_type_data = project_types.map do |project_type|
        count_level_data = count_levels.map do |count_level|

          {
            count_level: count_level,
            series: monthly_counts,
          }

        end
        {
          title: title,
          id: id,
        }
      end

      data = {
        title: title,
        id: id,
        demographics: demographics.map do |demo|
          bars = ['Exited', 'Returned']
          demo_names_meth = "demographic_#{demo.gsub(' ', '').underscore}".to_sym
          demo_colors_meth = "demographic_#{demo.gsub(' ', '').underscore}_colors".to_sym
          names = send(demo_names_meth)
          keys = names.map { |key| to_key(key) }
          colors = send(demo_colors_meth)
          scope = enrollment_scope
          # scope = filter_for_year(scope, Date.new(options[:year]))
          scope = filter_for_count_level(scope, 'Households')
          exited_household_count = scope.count
          # NOTE: we filter return date on write and only add if the client returned within a year
          returned_household_count = scope.where.not(return_date: nil).count
          {
            demographic: demo,
            config: {
              keys: keys,
              names: keys.map.with_index { |key, i| [key, names[i]] }.to_h,
              colors: keys.map.with_index { |key, i| [key, colors[i]] }.to_h,
              label_colors: keys.map.with_index { |key, i| [key, label_color(colors[i])] }.to_h,
            },
            series: send(type, { bars: bars, demographic: demo, types: names }),
            exited_household_count: exited_household_count,
            returned_household_count: returned_household_count,
          }
        end,
      }
      @report.datasets.create!(
        identifier: identifier,
        data: data,
      )
      data
    end

    def stacked_data
      cohort_name = 'Exited'

      data(
        cohort_name,
        to_key(cohort_name),
        :stack,
      )
    end

    def stack(options)
      project_type = options[:project_type]
      demographic = options[:demographic]
      bars = project_type.present? ? [project_type] + options[:bars] : options[:bars]
      bars.map do |bar|
        {
          name: bar,
          series: relevant_date_range.map do |date|
            {
              date: date.strftime('%Y-%-m-%-d'),
              values: options[:types].map { |label| stack_value(date, bar, demographic, label) },
              household_count: 1, # NOTE: not used, just for JS compatability
            }
          end.compact,
        }
      end
    end

    def relevant_date_range
      date_range
    end

    private def filter_for_date(scope, date)
      # NOTE: even though we aggregate at the year level, we calculate the month range and let JS do the aggregation
      range = date.beginning_of_month .. date.end_of_month
      where_clause = date_query(range)
      scope.where(where_clause)
    end

    private def date_query(range)
      en_t = Enrollment.arel_table
      en_t[:exit_date].between(range).and(en_t[:exit_type].eq('Permanent'))
    end

    private def filter_for_year(scope, date)
      range = date.beginning_of_year .. date.end_of_year
      where_clause = date_query(range)
      scope.where(where_clause)
    end

    private def enrollment_scope
      report_enrollments_enrollment_scope.
        distinct.
        select(:destination_client_id)
    end

    def stack_value(date, bar, demographic, label)
      scope = enrollment_scope
      # NOTE: there is no picker for households, so we're always using individuals
      scope = filter_for_count_level(scope, 'Individuals')
      scope = filter_for_year(scope, date)
      scope = scope.where(exit_type: 'Permanent')

      scope = case bar
      when 'Returned'
        # NOTE: we filter return date on write and only add if the client returned within a year
        scope.where.not(return_date: nil)
      else
        # NOTE: date filter enforces exit type is permanent since everyone in the page
        # has to have exited to a permanent destination (or moved in)
        scope
      end

      scope = case demographic
      when 'Race'
        scope.where(Enrollment.arel_table[:race_list].matches("%#{label}%"))
      when 'Age', 'Gender'
        filter_for_type(scope, label)
      when 'Household Type'
        scope.where(household_type: label)
      end
      count = mask_small_populations(scope.count, mask: @report.mask_small_populations?)
      count
    end

    def bars
      identifier = "#{@report.cache_key}/#{self.class.name}/#{__method__}"
      existing = @report.datasets.find_by(identifier: identifier)
      return existing.data.with_indifferent_access if existing.present?

      scope = enrollment_scope
      # NOTE: there is no picker on this page currently, but this could be updated if necessary
      scope = filter_for_count_level(scope, 'Individuals')

      exited_scope = scope.where.not(exit_date: nil)
      # NOTE: we filter return date on write and only add if the client returned within a year
      returned_scope = exited_scope.where.not(return_date: nil)

      exited_counts = mask_small_populations(exited_scope.count, mask: @report.mask_small_populations?)
      returned_counts = mask_small_populations(returned_scope.count, mask: @report.mask_small_populations?)

      rates_of_return = returned_counts.values.zip(exited_counts.values).map do |returns, exits|
        rate = exits.zero? ? 0 : (returns.to_f / exits * 100).round(1)
        "#{rate}%"
      end
      data = {
        title: 'Returns to Homelessness',
        id: 'returns_to_homelessness',
        config: {
          colors: {
            exited: ['#336770', '#884D01'],
            returned: ['#85A4A9', '#B48F5F'],
          },
          keys: 'Exited',
        },
        series: [
          { name: 'exited', values: exited_counts },
          { name: 'returned', values: returned_counts },
          { name: 'rate', values: rates_of_return, table_only: true },
        ],
      }
      @report.datasets.create!(
        identifier: identifier,
        data: data,
      )
      data
    end
  end
end
