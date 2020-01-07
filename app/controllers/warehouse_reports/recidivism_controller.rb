###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports
  class RecidivismController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    def index
      columns = [:client_id, :project_name, :first_date_in_program, :last_date_in_program, :move_in_date, :computed_project_type, :id]
      @filter = ::Filters::DateRange.new(date_range_options)
      ph_scope = ph_source.open_between(start_date: @filter.start, end_date: @filter.end).distinct
      @ph_clients = ph_scope.pluck(*columns).
        map do |row|
          Hash[columns.zip(row)]
        end.
        group_by { |row| row[:client_id] }

      @homeless_clients = homeless_source.
        with_service_between(start_date: @filter.start, end_date: @filter.end).
        where(client_id: ph_scope.select(:client_id)).
        distinct.
        pluck(*columns).
        map do |row|
          Hash[columns.zip(row)]
        end.
        group_by { |row| row[:client_id] }

      # Throw away the homeless client if all homeless enrollments start before all PH enrollments
      # or start after all PH enrollments close
      @homeless_clients.delete_if do |client_id, enrollments|
        ph = @ph_clients[client_id]
        es_start_dates = enrollments.map { |en| en[:first_date_in_program] }
        remove = []
        ph.each do |enrollment|
          if enrollment[:move_in_date].blank?
            remove << true
          elsif es_start_dates.any? { |st_date| enrollment[:last_date_in_program].present? && st_date.in?(enrollment[:move_in_date]..enrollment[:last_date_in_program]) }
            remove << false
          elsif es_start_dates.any? { |st_date| enrollment[:last_date_in_program].blank? && st_date > enrollment[:move_in_date] }
            remove << false
          else # es enrollment opened after exit from PH
            remove << true
          end
        end
        remove.all?
      end

      @clients = client_source.where(id: @ph_clients.keys & @homeless_clients.keys).
        order(LastName: :asc, FirstName: :asc)

      respond_to do |format|
        format.html do
          @clients = @clients.page(params[:page]).per(25)
          client_ids = @clients.map(&:id)
          enrollment_ids = @homeless_clients.values_at(*client_ids).flatten.map { |m| m[:id] }
          @homeless_service = service_materialized_source.where(service_history_enrollment_id: enrollment_ids).group(:service_history_enrollment_id).count
          @homeless_service_dates = service_materialized_source.where(service_history_enrollment_id: enrollment_ids).group(:service_history_enrollment_id).maximum(:date)
        end
        format.xlsx do
          client_ids = @clients.map(&:id)
          enrollment_ids = @homeless_clients.values_at(*client_ids).flatten.map { |m| m[:id] }
          @homeless_service = service_materialized_source.where(service_history_enrollment_id: enrollment_ids).group(:service_history_enrollment_id).count
          @homeless_service_dates = service_materialized_source.where(service_history_enrollment_id: enrollment_ids).group(:service_history_enrollment_id).maximum(:date)
          filename = "Recidivism-#{@filter.start.strftime('%Y-%m-%d')}-to-#{@filter.end.strftime('%Y-%m-%d')}.xlsx"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    def ph_source
      GrdaWarehouse::ServiceHistoryEnrollment.ph
    end

    def service_source
      GrdaWarehouse::ServiceHistoryService
    end

    def service_materialized_source
      GrdaWarehouse::ServiceHistoryServiceMaterialized
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
      { start: start_date, end: end_date }
    end
  end
end
