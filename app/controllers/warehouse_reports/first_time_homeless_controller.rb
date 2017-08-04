module WarehouseReports
  class FirstTimeHomelessController < ApplicationController
    before_action :require_can_view_reports!

    def index
      date_range_options = params.require(:first_time_homeless).permit(:start, :end) if params[:first_time_homeless].present?
      @range = ::Filters::DateRange.new(date_range_options)

      @clients = client_source
      if @range.valid?
        ht = history.arel_table
        @clients = @clients.
          joins(:first_service_history).
          preload(:first_service_history, first_service_history: [:organization, :project], source_clients: :data_source).
          entered_in_range(@range.range).
          select( :id, :FirstName, :LastName, ht[:date] ).
          order( ht[:date], :LastName, :FirstName )
        @project_types = params.try(:[], :first_time_homeless).try(:[], :project_types) || []
        @project_types.reject!(&:empty?)
        if @project_types.any?
          @project_types.map!(&:to_i)
          @clients = @clients.where(ht[history.project_type_column].in(@project_types))
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
      @range = ::Filters::DateRange.new({start: 1.year.ago, end: 1.day.ago})
      @counts = history.
        first_date.
        select(:date).
        where(date: @range.range).
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