###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module InactiveClientReport::WarehouseReports
  class ReportsController < ApplicationController
    include WarehouseReportAuthorization
    include AjaxModalRails::Controller
    include ArelHelper
    include BaseFilters

    before_action :set_report

    def index
      @excel_export = ::InactiveClientReport::DocumentExports::ReportExcelExport.new
      respond_to do |format|
        format.html do
          @pagy, @clients = pagy(@report.clients.order(:last_name, :first_name))
          @report.client_ids = @clients.map(&:id)
        end
        format.xlsx do
          @report.client_ids = @report.clients.map(&:id)
          filename = "#{@report.name} - #{Time.current.to_fs(:db)}.xlsx"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    private def set_report
      @report = report_class.new(@filter)
    end

    private def report_class
      InactiveClientReport::Report
    end

    def filter_params
      return default_filter_options unless params[:filters].present?

      params.permit(filters: @filter.known_params)
    end
    helper_method :filter_params

    private def default_filter_options
      {
        filters: {
          require_service_during_range: false,
          project_type_codes: ['ce'],
          end_date: Date.yesterday,
          start_date: 3.months.ago.to_date,
          days_since_contact_min: 30,
          days_since_contact_max: 90,
        },
      }
    end

    private def filter_class
      ::Filters::FilterBase
    end
  end
end
