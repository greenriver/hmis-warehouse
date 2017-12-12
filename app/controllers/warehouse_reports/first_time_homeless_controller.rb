module WarehouseReports
  class FirstTimeHomelessController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization
    def index
      date_range_options = params.require(:first_time_homeless).permit(:start, :end) if params[:first_time_homeless].present?
      @range = ::Filters::DateRange.new(date_range_options)

      @clients = client_source
      if @range.valid?
        @clients = @clients.
          joins(:first_service_history).
          preload(:first_service_history, first_service_history: [:organization, :project], source_clients: :data_source).
          entered_in_range(@range.range).
          select( :id, :FirstName, :LastName, sh_t[:date], :VeteranStatus ).
          order( sh_t[:date], :LastName, :FirstName )
        @project_types = params.try(:[], :first_time_homeless).try(:[], :project_types) || []
        @project_types.reject!(&:empty?)
        if @project_types.any?
          @project_types.map!(&:to_i)
          @clients = @clients.where(sh_t[history.project_type_column].in(@project_types))
        end
        @cohort = params.try(:[], :first_time_homeless).try(:[], :cohort) || 'all'
        case @cohort
        when 'individual-only'
          @clients = @clients.where(warehouse_client_service_history: {presented_as_individual: true})
        when 'family-only'
          @clients = @clients.where(warehouse_client_service_history: {presented_as_individual: false})
        when 'veterans'
          @clients = @clients.where(VeteranStatus: 1)
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
      @cohort = params.try(:[], :cohort) || 'all'
      
      @range = ::Filters::DateRange.new({start: start_date, end: end_date})
      @counts = history.
        first_date.
        select(:date).
        where(date: @range.range)

      if @project_types.any?
        @project_types.map!(&:to_i)
        @counts = @counts.where(sh_t[history.project_type_column].in(@project_types))
      end

      case @cohort
      when 'individual-only'
        @counts = @counts.where(presented_as_individual: true)
      when 'family-only'
        @counts = @counts.where(presented_as_individual: false)
      when 'veterans'
        @counts = @counts.joins(:client).where(c_t[:VeteranStatus].eq(1))
      end
      @counts = @counts.
        order(date: :asc).
        group(:date).
        count
      render json: @counts
    end

    private def history
      GrdaWarehouse::ServiceHistory
    end

    private def client_source
      GrdaWarehouse::Hud::Client.destination
    end

    def project_source
      GrdaWarehouse::Hud::Project
    end
  end
end
