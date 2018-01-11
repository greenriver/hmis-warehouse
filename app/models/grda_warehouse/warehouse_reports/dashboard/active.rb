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
      @labels.each do |key, _|
        project_type = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[key]
        enrollments_for_type = @enrollments.values.
          flatten(1).
          select do |m| 
            ::HUD::project_type_brief(m[:project_type]).downcase.to_sym == key
          end
        clients_served = homeless_service_history_source.
          service_within_date_range(start_date: @range.start, end_date: @range.end + 1.day).
          where(service_history_source.project_type_column => project_type).
          distinct.
          pluck(:client_id)
        enrollments_for_type = enrollments_for_type.select{|e| clients_served.include?(e[:client_id])}
        client_ids = enrollments_for_type.map do |enrollment|
            enrollment[:client_id]
          end.uniq
        @data[:clients][:data] << client_ids.count
        @data[:enrollments][:data] << enrollments_for_type.count
        @clients += client_ids
      end
      @clients = @clients.uniq
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