###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
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
      @excel_export = ::ClientDocumentsReport::DocumentExports::ReportExcelExport.new
      respond_to do |format|
        format.html do
          @pagy, @clients = pagy(@report.clients.order(:last_name, :first_name))
        end
        format.xlsx do
          filename = "Inactive Client Report - #{Time.current.to_s(:db)}.xlsx"
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
      params.permit(filters: @filter.known_params)
    end
    helper_method :filter_params

    private def filter_class
      ::Filters::FilterBase
    end
  end
end
