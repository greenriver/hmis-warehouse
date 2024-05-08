###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ClientDocumentsReport::WarehouseReports
  class ReportsController < ApplicationController
    include WarehouseReportAuthorization
    include AjaxModalRails::Controller
    include ArelHelper
    include BaseFilters

    before_action :set_report

    def index
      @excel_export = ::ClientDocumentsReport::DocumentExports::ReportExcelExport.new
      respond_to do |format|
        format.html do
          @initialized = @filter.required_files.present?
          return unless @initialized

          @pagy, @clients = pagy(@report.clients.order(:last_name, :first_name))
        end
        format.xlsx do
          filename = "Client Documents - #{Time.current.to_fs(:db)}.xlsx"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    private def set_report
      @filter.update(enforce_one_year_range: false)
      @report = report_class.new(@filter)
    end

    private def report_class
      ClientDocumentsReport::Report
    end

    private def set_filter
      @filter = filter_class.new(
        user_id: current_user.id,
        enforce_one_year_range: false,
        require_service_during_range: false,
        default_project_type_codes: report_class.default_project_type_codes,
      )
      @filter.update(filter_params[:filters]) if filter_params[:filters].present?
    end

    def filter_params
      params.permit(filters: @filter.known_params)
    end
    helper_method :filter_params

    private def filter_class
      ::Filters::FilterBase
    end
  end
end
