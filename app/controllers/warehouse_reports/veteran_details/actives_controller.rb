module WarehouseReports::VeteranDetails
  class ActivesController < WarehouseReportsController
    include ArelHelper
    include ArelTable
    include ClientActiveCalculations
    before_action :require_can_view_clients!

    CACHE_EXPIRY = if Rails.env.production? then 8.hours else 20.seconds end

    def index
      date_range_options = params.permit(range: [:start, :end])[:range]
      @range = ::Filters::DateRange.new(date_range_options)
      
      @start_date = @range.start
      @end_date = @range.end
      # @enrollments = Rails.cache.fetch("active-vet-enrollments", expires_in: CACHE_EXPIRY) do
      @enrollments = begin
        active_client_service_history(range: @range)
      end
      # respond_to do |format|
      #   format.html{ @enrollments.page(params[:page]).per(50)}
      # end
    end

    def client_source
      GrdaWarehouse::Hud::Client.destination.veteran
    end

    def related_report
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: 'warehouse_reports/veteran_details/actives')
    end
  end
end
