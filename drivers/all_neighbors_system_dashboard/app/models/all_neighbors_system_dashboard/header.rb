module AllNeighborsSystemDashboard
  class Header < DashboardData
    def initialize(...)
      super
    end

    def self.cache_data(report)
      instance = new(report)
      instance.header_data
    end

    def tabs
      [
        { name: 'Housing Placements' },
        # { name: 'Time To Obtain Housing' },
        { name: 'Returns To Homelessness' },
        # { name: 'Unhoused Population' },
      ].map { |tab| tab.merge({ id: tab[:name].gsub(' ', '').underscore }) }
    end

    def header_data
      [
        {
          id: 'individuals_housed',
          icon: 'icon-group-alt',
          value: housed_count,
          name: 'Individuals Housed To-Date',
          display_method: :number_with_delimiter,
        },
        {
          id: 'days_to_obtain_housing',
          icon: 'icon-house',
          value: average_days_to_obtain_housing.round,
          name: 'Average Number of Days to Obtain Housing',
          display_method: :number_with_delimiter,
        },
        {
          id: 'no_return',
          icon: 'icon-clip-board-check',
          value: no_return_percent,
          name: 'Did not return to homelessness after 12 months',
        },
      ]
    end

    def housed_count
      @housed_count ||= report_enrollments_enrollment_scope.housed.distinct.select(:destination_client_id).count
    end

    def average_days_to_obtain_housing
      en_t = Enrollment.arel_table
      report_enrollments_enrollment_scope.housed.average(
        datediff(
          Enrollment,
          'day',
          cl(en_t[:move_in_date], en_t[:exit_date]),
          en_t[:entry_date],
        ),
      )
    end

    def no_return_percent
      return 0 if housed_count.zero?

      percent = ((report_enrollments_enrollment_scope.returned.select(:destination_client_id).count / housed_count.to_f) * 100).round
      "#{percent}%"
    end
  end
end
