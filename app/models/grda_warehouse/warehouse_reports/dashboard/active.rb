module GrdaWarehouse::WarehouseReports::Dashboard
  class Active < GrdaWarehouse::WarehouseReports::Dashboard::Base

    def self.params
      {
        start: 1.months.ago.beginning_of_month.to_date, 
        end: 1.months.ago.end_of_month.to_date,
      }
    end

    def run!
      # Active Clients
      start_date = parameters.with_indifferent_access[:start]
      end_date = parameters.with_indifferent_access[:end]
      @range = ::Filters::DateRange.new({start: start_date, end: end_date})

      @month_name = @range.start.to_time.strftime('%B')
      @enrollments = active_client_service_history(range: @range)
      @clients = []

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
      @cleaned_enrollments = {}
      @labels.each do |key, _|
        project_type = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[key].first
        clients_served = client_ids_served_within_range_and_project_type(project_type)
        enrollments_for_type = @enrollments.values.flatten(1).
          select do |m| 
            m[:project_type] == project_type && clients_served.include?(m[:client_id])
          end

        client_ids = enrollments_for_type.map{ |e| e[:client_id]}.uniq
        @data[:clients][:data] << client_ids.count
        @data[:enrollments][:data] << enrollments_for_type.count
        @clients += client_ids
        @cleaned_enrollments[project_type] = enrollments_for_type
      end
      @clients = @clients.uniq
      @client_count = @clients.size
      {
        enrollments: @cleaned_enrollments,
        month_name: @month_name,
        range: @range,
        clients: @clients,
        client_count: @client_count,
        labels: @labels,
        data: @data,
      }
    end

    def client_ids_served_within_range_and_project_type project_type
      homeless_service_history_source.
        service_within_date_range(start_date: @range.start, end_date: @range.end).
        where(service_history_source.project_type_column => project_type).
        distinct.
        pluck(:client_id)
    end

    def active_client_service_history range: 
      homeless_service_history_source.entry.
        joins(:client, :project).
        open_between(start_date: range.start, end_date: range.end).
        pluck(*service_history_columns.values).
        map do |row|
          Hash[service_history_columns.keys.zip(row)]
        end.group_by{|m| m[:client_id]}
    end

  end
end