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
      end
    end

  end
end
