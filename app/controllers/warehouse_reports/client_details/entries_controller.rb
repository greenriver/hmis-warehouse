module WarehouseReports::ClientDetails
  class EntriesController < ApplicationController
    include ArelHelper
    include ApplicationHelper
    include WarehouseReportAuthorization

    CACHE_EXPIRY = if Rails.env.production? then 8.hours else 20.seconds end

    def index
      @sub_population = (params.try(:[], :range).try(:[], :sub_population).presence || :all_clients).to_sym
      date_range_options = params.permit(range: [:start, :end, :sub_population])[:range]
      @range = ::Filters::DateRangeWithSubPopulation.new(date_range_options)
      @project_type_code = params[:project_type]&.to_sym || :es
      @project_type = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[@project_type_code]

      @start_date = @range.start
      @end_date = @range.end
      @enrollments_by_type = entered_enrollments_by_type(start_date: @start_date, end_date: @end_date)

      @client_enrollment_totals_by_type = client_totals_from_enrollments(enrollments: @enrollments_by_type)
      
      @entries_in_range_by_type = entries_in_range_from_enrollments(enrollments: @enrollments_by_type, start_date: @start_date, end_date: @end_date)

      @client_entry_totals_by_type = client_totals_from_enrollments(enrollments: @entries_in_range_by_type)
      
      @buckets = bucket_clients(entries: @entries_in_range_by_type)
      @data = setup_data_structure(start_date: @start_date)
      respond_to do |format|
        format.html {}
        format.xlsx do
          require_can_view_clients!
        end
      end
    end

    def client_source
      case @sub_population
      when :veteran
        GrdaWarehouse::Hud::Client.destination.veteran
      when :all_clients
        GrdaWarehouse::Hud::Client.destination
      when :youth
        GrdaWarehouse::Hud::Client.destination.unaccompanied_youth(start_date: @start_date, end_date: @end_date)
      when :parenting_youth
        GrdaWarehouse::Hud::Client.destination.parenting_youth(start_date: @range.start, end_date: @range.end)
      when :parenting_children
        GrdaWarehouse::Hud::Client.destination.parenting_juvenile(start_date: @range.start, end_date: @range.end)
      when :individual_adults
        GrdaWarehouse::Hud::Client.destination.individual_adult(start_date: @start_date, end_date: @end_date)
      when :non_veteran
        GrdaWarehouse::Hud::Client.destination.non_veteran
      when :family
        GrdaWarehouse::Hud::Client.destination.family(start_date: @start_date, end_date: @end_date)
      when :children
        GrdaWarehouse::Hud::Client.destination.children_only(start_date: @start_date, end_date: @end_date)
      end
    end

    def history_scope scope, sub_population
      scope_hash = {
        all_clients: scope,
        veteran: scope.veteran,
        youth: scope.unaccompanied_youth,
        parenting_youth: scope.parenting_youth,
        parenting_children: scope.parenting_juvenile,
        individual_adults: scope.individual_adult,
        non_veteran: scope.non_veteran,
        family: scope.family,
        children: scope.children_only,
      }
      scope_hash[sub_population.to_sym]
    end

    def service_history_source
      GrdaWarehouse::ServiceHistory
    end

    def homeless_service_history_source
      scope = service_history_source.
        where(service_history_source.project_type_column => @project_type)
      history_scope(scope, @sub_population)
    end

    def entered_columns 
      {
        project_type: sh_t[service_history_source.project_type_column].as('project_type').to_sql, 
        first_date_in_program: sh_t[:first_date_in_program].as('first_date_in_program').to_sql,
        last_date_in_program: sh_t[:last_date_in_program].as('last_date_in_program').to_sql, 
        client_id: sh_t[:client_id].as('client_id').to_sql,
        project_name: sh_t[:project_name].as('project_name').to_sql,
        first_name: c_t[:FirstName].as('first_name').to_sql,
        last_name: c_t[:LastName].as('last_name').to_sql,
        organization_name: o_t[:OrganizationName].as('organization_name').to_sql,
      }
    end
     
    def setup_data_structure start_date:
      month_name = start_date.to_time.strftime('%B')
      {
        first_time: {
          label: 'First time clients in the project type',
          data: [],
          backgroundColor: '#288BE4',
        },
        less_than_thirty: {
          label: "Clients with an entry in #{month_name} and an entry within 30 days prior to their most recent entry in #{month_name}",
          data: [],
          backgroundColor: '#704C70',
        },
        thirty_to_sixty: {
          label: "Clients with an entry in #{month_name} and between 30 and 60 days prior",
          data: [],
          backgroundColor: '#5672AA',
        },
        sixty_plus: {
          label: "Clients with an entry in #{month_name} and 60+ days prior",
          data: [],
          backgroundColor: '#45789C',
        },
      }
    end

    def client_totals_from_enrollments enrollments: 
      enrollments.map do |project_type, clients| 
        [
          project_type, 
          clients.count,
        ]
      end.to_h
    end

    def entries_in_range_from_enrollments enrollments:, start_date:, end_date:
        enrollments.map do |project_type, clients|
        [
          project_type,
          clients.select do |_, enrollments|
            enrollments.map do |enrollment|
              (start_date..end_date).include?(enrollment[:first_date_in_program])
            end.any?
          end
        ]
      end.to_h
    end

    # limit enrollments to those that were open during the range
    def enrollments_ongoing_in_date_range enrollments:, start_date:, end_date:
      enrollments.map do |project_type, clients|
        [
          project_type,
          clients.map do |id, enrollments|
            ongoing = enrollments.select do |enrollment|
              enrollment_end = enrollment[:last_date_in_program] || Date.today
              # Excellent discussion of why this works:
              # http://stackoverflow.com/questions/325933/determine-whether-two-date-ranges-overla
              # start_date < enrollment_end && end_date > enrollment[:first_date_in_program]
              dates_overlap(start_date, end_date, enrollment[:first_date_in_program], enrollment_end)
              
            end
            [id, ongoing]
          end.select do |_, enrollments|
            enrollments.any?
          end.to_h
        ]
      end.to_h
    end

    # all enrollments for clients who were active during the date range
    def entered_enrollments_by_type start_date:, end_date:
      enrollments_by_type = homeless_service_history_source.entry.
        joins(:client, :organization).
        where(client_id: 
          homeless_service_history_source.
          where(record_type: [:service, :entry]). # this catches the situation where we have an open enrollment but no service and the enrollment opens within the date
          where(sh_t[:date].gteq(start_date).and(sh_t[:date].lteq(end_date))).
          select(:client_id)
        ).
        order(date: :asc).
        pluck(*entered_columns.values).
        map do |row| 
          Hash[entered_columns.keys.zip(row)]
        end.
        group_by{ |m| m[:project_type]}
        {}.tap do |m|
          enrollments_by_type.each do |project_type, enrollments|
            m[project_type] = enrollments.group_by{|e| e[:client_id]}
          end
        end
    end

    def bucket_clients entries:
      buckets = {}
      entries.each do |project_type, clients|
        buckets[project_type] ||= {
          sixty_plus: {},
          thirty_to_sixty: {},
          less_than_thirty: {},
          first_time: {},
        }
        clients.each do |client_id, enrollments|
          if enrollments.count == 1
            buckets[project_type][:first_time][client_id] = enrollments
          else
            days = days_since_last_entry(enrollments)
            if days < 30
              buckets[project_type][:less_than_thirty][client_id] = enrollments
            elsif (30..60).include?(days)
              buckets[project_type][:thirty_to_sixty][client_id] = enrollments
            else # days > 60
              buckets[project_type][:sixty_plus][client_id] = enrollments
            end
          end
        end
      end
      buckets
    end

    def days_since_last_entry enrollments
      enrollments.last(2).map{|m| m[:first_date_in_program]}.reduce(:-).abs
    end

  end
end
