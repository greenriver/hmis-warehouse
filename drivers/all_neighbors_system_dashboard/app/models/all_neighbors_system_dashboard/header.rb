module AllNeighborsSystemDashboard
  class Header < DashboardData
    def self.cache_data(report)
      instance = new(report)
      instance.header_data
    end

    def tabs
      [
        { name: 'Housing Placements' },
        { name: 'Time To Obtain Housing' },
        { name: 'Returns To Homelessness' },
        # { name: 'Unhoused Population' },
      ].map { |tab| tab.merge({ id: tab[:name].gsub(' ', '').underscore }) }
    end

    def header_data
      [
        {
          id: 'individuals_housed',
          icon: 'icon-group-alt',
          value: mask_small_populations(housed_count, mask: @report.mask_small_populations?),
          name: 'Individuals Housed To-Date',
          display_method: :number_with_delimiter,
        },
        {
          id: 'days_to_obtain_housing',
          icon: 'icon-house',
          value: average_days_to_obtain_housing.round.abs,
          name: 'Average Number of Days to Obtain Housing',
          display_method: :number_with_delimiter,
        },
        {
          id: 'no_return',
          icon: 'icon-clip-board-check',
          value: returned_percent,
          name: 'Returned to Homelessness Within 12 Months',
        },
      ]
    end

    def housed_count
      @housed_count ||= begin
        scope = housed_total_scope
        # Enforce the same project limits as the subsequent charts
        scope = filter_for_type(scope, 'All')
        scope.select(:destination_client_id).count
      end
    end

    def average_days_to_obtain_housing
      en_t = Enrollment.arel_table
      report_enrollments_enrollment_scope.housed_in_range(@report.filter.range, filter: @report.filter).average(
        datediff(
          Enrollment,
          'day',
          cl(en_t[:move_in_date], en_t[:exit_date]),
          en_t[:entry_date],
        ),
      )
    end

    def returned_percent
      return 0 if housed_count.zero?

      percent = ((report_enrollments_enrollment_scope.returned.distinct.select(:destination_client_id).count / housed_count.to_f) * 100).round
      "#{percent}%"
    end
  end
end
