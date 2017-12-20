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
        @clients = @clients.
          joins(:first_service_history).
          preload(:first_service_history, first_service_history: [:organization, :project], source_clients: :data_source).
          entered_in_range(@range.range).
          select( :id, :FirstName, :LastName, sh_t[:date], :VeteranStatus, :DOB ).
          order( sh_t[:date], :LastName, :FirstName )
        @project_types = params.try(:[], :first_time_homeless).try(:[], :project_types) || []
        @project_types.reject!(&:empty?)
        if @project_types.any?
          @project_types.map!(&:to_i)
          @clients = @clients.where(sh_t[history.project_type_column].in(@project_types))
        end
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

    # Present a chart of the counts from the previous year
    def summary
      start_date = params[:start] || 1.year.ago
      end_date = params[:end] || 1.day.ago
      @project_types = params.try(:[], :project_types) || '[]'
      @project_types = JSON.parse(params[:project_types])
      @sub_population = (params.try(:[], :sub_population) || :all_clients).to_sym
      
      @range = ::Filters::DateRange.new({start: start_date, end: end_date})
      @counts = history.first_date.
        select(:date).
        where(date: @range.range)

      if @project_types.any?
        @project_types.map!(&:to_i)
        @counts = @counts.where(sh_t[history.project_type_column].in(@project_types))
      end

      @counts = @counts.
        order(date: :asc).
        group(:date).
        count
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
