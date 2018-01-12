module WarehouseReports
  class FirstTimeHomelessController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization
    def index
      date_range_options = params.require(:first_time_homeless).permit(:start, :end) if params[:first_time_homeless].present?
      @range = ::Filters::DateRange.new(date_range_options)
      @sub_population = (params.try(:[], :first_time_homeless).try(:[], :sub_population) || :all_clients).to_sym

      @clients = client_source
      if @range.valid?
        @project_types = params.try(:[], :first_time_homeless).try(:[], :project_types) || GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS
        @project_types.reject!(&:empty?)
        @project_types.map!(&:to_i)
        if @project_types.empty?
          @project_types = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS
        end

        # Find client ids of those who's first entry was in the range and who received at least
        # one service of the type within the range
        client_ids = clients_with_starts_and_service_in_range()

        @clients = @clients.joins(:first_service_history).
          preload(:first_service_history, first_service_history: [:organization, :project], source_clients: :data_source).
          where(sh_t[:record_type].eq('first')).
          where(id: client_ids).
          distinct.
          select( :id, :FirstName, :LastName, sh_t[:date], :VeteranStatus, :DOB ).
          order( sh_t[:date], :LastName, :FirstName )
      else
        @clients = @clients.none
      end
      respond_to do |format|
        format.html {
          @clients = @clients.page(params[:page]).per(25)
        }
        format.xlsx {}
      end
    end

    # Limit to clients who had their first enrollment within the range, *and* had at least one day of service
    # during the range as well in the same project type
    def clients_with_starts_and_service_in_range
      [].tap do |client_ids|
        @project_types.each do |project_type|
          client_ids << history.first_date.
            started_between(start_date: @range.start, end_date: @range.end).
            where(history.project_type_column => project_type).
            where(
              client_id: history.service_within_date_range(start_date: @range.start, end_date: @range.end ).
                where(history.project_type_column => project_type).
                select(:client_id)
            ).distinct.pluck(:client_id)
        end
      end.flatten
    end

    # Present a chart of the counts from the previous year
    def summary
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
      client_ids = clients_with_starts_and_service_in_range()
      @counts = history.first_date.select(:date, :client_id).where(client_id: client_ids).where(date: @range.range)
      @counts = @counts.where(sh_t[history.project_type_column].in(@project_types)).
        order(date: :asc).pluck(:date, :client_id).
        group_by{|date, client_id| date}.
        map{|date, clients| [date, clients.count]}.to_h
      render json: @counts
    end

    def history
      case @sub_population
      when :veteran
        GrdaWarehouse::ServiceHistory.veteran
      when :all_clients
        GrdaWarehouse::ServiceHistory
      when :youth
        GrdaWarehouse::ServiceHistory.unaccompanied_youth
      when :parenting_youth
        GrdaWarehouse::ServiceHistory.parenting_youth
      when :parenting_children
        GrdaWarehouse::ServiceHistory.parenting_juvenile
      when :individual_adults
        GrdaWarehouse::ServiceHistory.individual_adult
      when :non_veteran
        GrdaWarehouse::ServiceHistory.non_veteran
      when :family
        GrdaWarehouse::ServiceHistory.family
      when :children
        GrdaWarehouse::ServiceHistory.children_only
      end
    end

    def client_source
      case @sub_population
      when :veteran
        GrdaWarehouse::Hud::Client.destination.veteran
      when :all_clients
        GrdaWarehouse::Hud::Client.destination
      when :youth
        GrdaWarehouse::Hud::Client.destination.unaccompanied_youth(start_date: @range.start, end_date: @range.end)
      when :parenting_youth
        GrdaWarehouse::Hud::Client.destination.parenting_youth(start_date: @range.start, end_date: @range.end)
      when :parenting_children
        GrdaWarehouse::Hud::Client.destination.parenting_juvenile(start_date: @range.start, end_date: @range.end)
      when :individual_adults
        GrdaWarehouse::Hud::Client.destination.individual_adult(start_date: @range.start, end_date: @range.end)
      when :non_veteran
        GrdaWarehouse::Hud::Client.destination.non_veteran
      when :family
        GrdaWarehouse::Hud::Client.destination.family(start_date: @range.start, end_date: @range.end)
      when :children
        GrdaWarehouse::Hud::Client.destination.children_only(start_date: @range.start, end_date: @range.end)
      end
    end

    def project_source
      GrdaWarehouse::Hud::Project
    end
  end
end
