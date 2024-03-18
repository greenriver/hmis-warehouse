###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AllNeighborsSystemDashboard
  class Header < DashboardData
    def self.cache_data(report)
      instance = new(report)
      instance.header_data
    end

    def tabs
      [
        # { name: 'Housing Placements' },
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
          value: mask_small_populations(housed_count, mask: @report.mask_small_populations?),
          name: 'Housing Placements',
          display_method: :number_with_delimiter,
        },
        {
          id: 'days_to_obtain_housing',
          icon: 'icon-house',
          value: average_days_to_obtain_housing.round.abs,
          name: 'Average Number of Days Between Referral and Housing Move-in',
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
      AllNeighborsSystemDashboard::TimeToObtainHousing.new(@report).overall_average_time(:referral_to_move_in)
    end

    def returned_percent
      return 0 if housed_count.zero?

      percent = ((returned_total_scope.distinct.select(:destination_client_id).count / housed_count.to_f) * 100).round
      "#{percent}%"
    end
  end
end
