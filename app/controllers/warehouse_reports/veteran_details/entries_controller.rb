module WarehouseReports::VeteranDetails
  class EntriesController < ApplicationController
    include ArelHelper
    include ClientEntryCalculations
    before_action :require_can_view_reports!
    before_action :require_can_view_clients!

    CACHE_EXPIRY = if Rails.env.production? then 8.hours else 20.seconds end

    def index
      date_range_options = params.permit(range: [:start, :end])[:range]
      @range = ::Filters::DateRange.new(date_range_options)
      @project_type_code = params[:project_type]&.to_sym || :es
      @project_type = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[@project_type_code]

      @start_date = @range.start
      @end_date = @range.end
      @enrollments_by_type = Rails.cache.fetch("entered-vet-enrollments_by_project_type-#{@project_type}", expires_in: CACHE_EXPIRY) do
        entered_enrollments_by_type start_date: @start_date, end_date: @end_date
      end

      @client_enrollment_totals_by_type = client_totals_from_enrollments(enrollments: @enrollments_by_type)
      
      @entries_in_range_by_type = entries_in_range_from_enrollments(enrollments: @enrollments_by_type, start_date: @start_date, end_date: @end_date)

      @client_entry_totals_by_type = client_totals_from_enrollments(enrollments: @entries_in_range_by_type)
      
      @buckets = bucket_clients(entries: @entries_in_range_by_type)
      @data = setup_data_structure(start_date: @start_date)
    end

    def client_source
      GrdaWarehouse::Hud::Client.destination.veteran
    end

    def service_history_source
      GrdaWarehouse::ServiceHistory
    end

    def homeless_service_history_source
      service_history_source.
        where(service_history_source.project_type_column => @project_type).
        where(client_id: client_source)
    end
  end
end