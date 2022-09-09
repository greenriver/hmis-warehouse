###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AccessLogs::WarehouseReports
  class ReportsController < ApplicationController
    include WarehouseReportAuthorization
    include BaseFilters

    def index
      @exports = AccessLogs::Export.diet_select.where(user_id: current_user.id).
        order(created_at: :desc)
    end

    def create
      filename = "Access Logs for #{@filter.start.to_s(:db)} to #{@filter.end.to_s(:db)} generated #{Time.current.to_s(:db)}"
      file = AccessLogs::Export.create!(
        user_id: current_user.id,
        status: 'pending',
        version: 1,
        filename: filename,
      )

      ::WarehouseReports::AccessLogsExportJob.perform_later(
        filter_params: @filter.to_h,
        filter_user_id: filter_params[:filters][:user_id],
        current_user_id: current_user.id,
        cas_user_id: filter_params[:filters]['cas_user_id'],
        file_id: file.id,
      )
      flash[:notice] = 'Access Log file generation queued'
      redirect_to access_logs_warehouse_reports_reports_path
      # respond_with(file, location: access_logs_warehouse_reports_reports_path)
    end

    private def filter_class
      ::Filters::FilterBase
    end

    def filter_params
      return { filters: { start: 3.months.ago.to_date, end: 1.days.ago.to_date } } unless params[:filters].present?

      clean = params.permit(filters: [:user_id, :cas_user_id] + @filter.known_params)
      clean[:filters][:enforce_one_year_range] = false
      clean
    end
    helper_method :filter_params
  end
end
