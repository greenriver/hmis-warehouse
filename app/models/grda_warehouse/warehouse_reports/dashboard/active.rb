###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::WarehouseReports::Dashboard
  class Active < GrdaWarehouse::WarehouseReports::Dashboard::Base

    attr_accessor :range

    def self.params
      start = 1.months.ago.beginning_of_month.to_date
      # unless Rails.env.production?
      #   start = 6.months.ago.beginning_of_month.to_date
      # end
      {
        start: start,
        end: 1.months.ago.end_of_month.to_date,
      }
    end

    def set_date_range
      start_date = parameters.with_indifferent_access[:start]
      end_date = parameters.with_indifferent_access[:end]
      @range = ::Filters::DateRange.new({start: start_date, end: end_date})
      @month_name = @range.start.to_time.strftime('%B')
    end


    scope :for_month, -> (date: Date.current) do
      start_of_month = date&.to_date&.beginning_of_month
      where("parameters->> 'start' = ? or parameters ->> 'start_date' = ?", start_of_month, start_of_month)
    end

    def init
      set_date_range()

      @clients = []
      @enrollments = {}
      @labels = GrdaWarehouse::Hud::Project::HOMELESS_TYPE_TITLES.sort.to_h
      @data = {
        clients: {
          label: 'Client count',
          backgroundColor: '#45789C',
          data: [],
        },
        enrollments: {
          label: 'Enrollment count',
          backgroundColor: '#704C70',
          data: [],
        },
      }
    end

    def run!
      # Active Clients
      init() # setup some useful buckets

      @labels.each do |key, _|
        project_type = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[key]

        enrollment_counts_by_client = enrollment_counts(project_type)
        enrollment_count = enrollment_counts_by_client.values.sum
        @data[:clients][:data] << enrollment_counts_by_client.count
        @data[:enrollments][:data] << enrollment_count
        @clients += enrollment_counts_by_client.keys
        @enrollments[project_type] = enrollment_count
      end

      @clients.uniq!
      @client_count = @clients.size
      {
        enrollments: @enrollments,
        month_name: @month_name,
        range: @range,
        clients: @clients,
        client_count: @client_count,
        labels: @labels,
        data: @data,
      }
    end
  end
end
