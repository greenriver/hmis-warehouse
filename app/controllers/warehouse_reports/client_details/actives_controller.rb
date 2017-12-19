module WarehouseReports::ClientDetails
  class ActivesController < ApplicationController
    include ArelHelper
    include ArelTable
    include ClientActiveCalculations
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

  end
end
