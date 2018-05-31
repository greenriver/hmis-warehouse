module WarehouseReports
  class RecidivismController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    def index
      columns = [:client_id, :project_name, :first_date_in_program, :last_date_in_program, :id]
      @filter = ::Filters::DateRange.new(date_range_options)
      @ph_clients = ph_source.open_between(start_date: @filter.start, end_date: @filter.end).distinct.
        pluck(*columns).
        map do |row|
          Hash[columns.zip(row)]
        end.
        group_by{|row| row[:client_id]}

      @homeless_clients = homeless_source.with_service_between(start_date: @filter.start, end_date: @filter.end).distinct.
        pluck(*columns).
        map do |row|
          Hash[columns.zip(row)]
        end.
        group_by{|row| row[:client_id]}
      
      @clients = client_source.where(id: @ph_clients.keys & @homeless_clients.keys).
        order(LastName: :asc, FirstName: :asc).
        page(params[:page]).per(25)

      client_ids = @clients.map(&:id)
      enrollment_ids = @homeless_clients.values_at(*client_ids).flatten.map{|m| m[:id]}
      @homeless_service = service_source.where(service_history_enrollment_id: enrollment_ids).group(:service_history_enrollment_id).count
    end

    def ph_source
      GrdaWarehouse::ServiceHistoryEnrollment.ph
    end

    def service_source
      GrdaWarehouse::ServiceHistoryService
    end

    def homeless_source
      project_types = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:so] + GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:es]
      GrdaWarehouse::ServiceHistoryEnrollment.in_project_type(project_types)
    end

    def client_source
      GrdaWarehouse::Hud::Client.destination
    end

    def date_range_options
      start_date = params[:filter].try(:[], :start) || 1.months.ago.to_date
      end_date = params[:filter].try(:[], :end) || 1.days.ago.to_date
      {start: start_date, end: end_date}
    end
  end
end
