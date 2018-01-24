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

        set_first_time_homeless_client_ids()

        @clients = client_source.joins(:first_service_history).
          preload(:first_service_history, first_service_history: [:organization, :project], source_clients: :data_source).
          where(she_t[:record_type].eq('first')).
          where(id: @first_time_client_ids.to_a).
          distinct.
          select( :id, :FirstName, :LastName, she_t[:date], :VeteranStatus, :DOB ).
          order( she_t[:date], :LastName, :FirstName )
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

    def set_first_time_homeless_client_ids
      @project_types.each do |project_type|
        @first_time_client_ids += first_time_homeless_within_range(project_type).distinct.pluck(:client_id)
      end
    end

    def first_time_homeless_within_range project_type
      first_scope = enrollment_source.entry.in_project_type(project_type).
        with_service_between(start_date: @range.start, end_date: @range.end).
        where(client_id: enrollment_source.first_date.
          started_between(start_date: @range.start, end_date: @range.end).
          in_project_type(project_type).select(:client_id)
        )
      history_scope(first_scope, @sub_population)
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

      set_first_time_homeless_client_ids()

      @counts = enrollment_source.first_date.
        select(:date, :client_id).
        where(client_id: @first_time_client_ids.to_a).
        where(date: @range.range).
        in_project_type(@project_types).
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

    def enrollment_source
      GrdaWarehouse::ServiceHistoryEnrollment
    end

    def service_source
      GrdaWarehouse::ServiceHistoryService
    end

  end
end
