module WarehouseReports
  class FirstTimeHomelessController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization
    def index
      date_range_options = params.require(:first_time_homeless).permit(:start, :end) if params[:first_time_homeless].present?
      @range = ::Filters::DateRange.new(date_range_options)
      @sub_population = (params.try(:[], :first_time_homeless).try(:[], :sub_population) || :all_clients).to_sym

      if @range.valid?
        @first_time_client_ids = Set.new
        @project_types = params.try(:[], :first_time_homeless).try(:[], :project_types) || GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES
        @project_types.reject!(&:blank?)
        @project_types.map!(&:to_i)
        if @project_types.empty?
          @project_types = GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES
        end

        set_first_time_client_ids()
        set_first_time_ever()
        
        @clients = client_source.joins(:first_service_history).
          preload(:first_service_history, first_service_history: [:organization, :project], source_clients: :data_source).
          where(sh_t[:record_type].eq('first')).
          where(id: @first_time_ever.to_a).
          distinct.
          select( :id, :FirstName, :LastName, sh_t[:date], :VeteranStatus, :DOB ).
          order( sh_t[:date], :LastName, :FirstName )
      else
        @clients = client_source.none
      end
      respond_to do |format|
        format.html {
          @clients = @clients.page(params[:page]).per(25)
        }
        format.xlsx {}
      end
    end

    def set_first_time_client_ids
      # fetch all entry dates for clients above
      # This has a side-effect of saving off the client ids for those who this is the first time in the
      # project type
      @buckets = @project_types.map do |project_type|
        entry_dates = entry_dates_by_client(project_type)
        [project_type, bucket_clients(entry_dates)]
      end.to_h
    end

    def set_first_time_ever
      @first_time_ever = service_history_source.homeless.first_date.
          where(client_id: @first_time_client_ids.to_a, first_date_in_program: @range.range).
          distinct.
          pluck(:client_id)
    end

    def client_source
      GrdaWarehouse::Hud::Client.destination
    end

    # Present a chart of the counts from the previous year
    def summary
      @first_time_client_ids = Set.new
      start_date = params[:start] || 1.year.ago
      end_date = params[:end] || 1.day.ago
      @project_types = params.try(:[], :project_types) || '[]'
      @project_types = JSON.parse(params[:project_types])
      @project_types.map!(&:to_i)
      if @project_types.empty?
        @project_types = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS
      end
      @sub_population = (params.try(:[], :sub_population) || :all_clients).to_sym
      
      @range = ::Filters::DateRange.new({start: start_date, end: end_date})
      set_first_time_client_ids()
      set_first_time_ever()
      @counts = GrdaWarehouse::ServiceHistory.first_date.select(:date, :client_id).
        where(client_id: @first_time_ever.to_a).where(date: @range.range)
      @counts = @counts.where(sh_t[GrdaWarehouse::ServiceHistory.project_type_column].in(@project_types)).
        order(date: :asc).pluck(:date, :client_id).
        group_by{|date, client_id| date}.
        map{|date, clients| [date, clients.count]}.to_h
      render json: @counts
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

    def service_scope project_type
      homeless_service_history_source(project_type).
      service_within_date_range(start_date: @range.start, end_date: @range.end).
      where(service_history_source.project_type_column => project_type)
    end

    def homeless_service_history_source project_type
      scope = service_history_source.
        where(service_history_source.project_type_column => project_type)
      history_scope(scope, @sub_population)
    end

    def entry_dates_by_client project_type
      @entry_dates_by_client = {}
      homeless_service_history_source(project_type).
      entry.
      where(sh_t[:first_date_in_program].lteq(@range.end)).
      where(service_history_source.project_type_column => project_type).
      where(client_id: service_scope(project_type).started_between(start_date: @range.start, end_date: @range.end).distinct.select(:client_id)).
      order(first_date_in_program: :desc).
      pluck(:client_id, :first_date_in_program).
      each do |client_id, first_date_in_program|
        @entry_dates_by_client[client_id] ||= []
        @entry_dates_by_client[client_id] << first_date_in_program
      end
      @entry_dates_by_client
    end

    def bucket_clients clients
      buckets = {
        sixty_plus: 0,
        thirty_to_sixty: 0,
        less_than_thirty: 0,
        first_time: 0,
      }

      clients.each do |client_id, entry_dates|
        if entry_dates.count == 1
          buckets[:first_time] += 1
          @first_time_client_ids << client_id
        else
          days = days_since_last_entry(entry_dates)
          if days < 30
            buckets[:less_than_thirty] += 1
          elsif (30..60).include?(days)
            buckets[:thirty_to_sixty] += 1
          else # days > 60
            buckets[:sixty_plus] += 1
          end
        end
      end
      buckets
    end

    def days_since_last_entry entry_dates
      entry_dates.first(2).reduce(:-).abs
    end
  end
end
