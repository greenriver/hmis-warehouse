module WarehouseReports::ClientDetails
  class ActivesController < ApplicationController
    include ArelHelper
    include ArelTable
    include WarehouseReportAuthorization

    CACHE_EXPIRY = if Rails.env.production? then 8.hours else 20.seconds end

    def index
      @sub_population = (params.try(:[], :range).try(:[], :sub_population).presence || :all_clients).to_sym
      date_range_options = params.permit(range: [:start, :end, :sub_population])[:range]
      @range = ::Filters::DateRangeWithSubPopulation.new(date_range_options)
      
      @start_date = @range.start
      @end_date = @range.end
      # @enrollments = Rails.cache.fetch("active-vet-enrollments", expires_in: CACHE_EXPIRY) do
      @enrollments = begin
        active_client_service_history(range: @range)
      end
      respond_to do |format|
        format.html {}
        format.xlsx do
          require_can_view_clients!
        end
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

    def service_history_columns
      {
        client_id: sh_t[:client_id].as('client_id').to_sql, 
        project_id:  sh_t[:project_id].as('project_id').to_sql, 
        first_date_in_program:  sh_t[:first_date_in_program].as('first_date_in_program').to_sql, 
        last_date_in_program:  sh_t[:last_date_in_program].as('last_date_in_program').to_sql, 
        project_name:  sh_t[:project_name].as('project_name').to_sql, 
        project_type:  sh_t[service_history_source.project_type_column].as('project_type').to_sql, 
        organization_id:  sh_t[:organization_id].as('organization_id').to_sql,
        first_name: c_t[:FirstName].as('first_name').to_sql,
        last_name: c_t[:LastName].as('last_name').to_sql,
      }
    end

    def active_client_service_history range: 
      homeless_service_history_source.joins(:client).
        entry.
        open_between(start_date: range.start, end_date: range.end + 1.day).
        where(
          client_id: homeless_service_history_source.
                      service_within_date_range(start_date: range.start, end_date: range.end + 1.day).
                      select(:client_id)
        ).
        pluck(*service_history_columns.values).
        map do |row|
          Hash[service_history_columns.keys.zip(row)]
        end.select do |row|
          # throw out any that start after the range
          row[:first_date_in_program] <= range.end
        end.
        group_by{|m| m[:client_id]}
    end

    def service_history_source
      GrdaWarehouse::ServiceHistory
    end

    def homeless_service_history_source
      scope = service_history_source.homeless
      history_scope(scope, @sub_population)
    end

  end
end
