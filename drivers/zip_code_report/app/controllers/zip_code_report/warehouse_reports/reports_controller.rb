###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ZipCodeReport::WarehouseReports
  class ReportsController < ApplicationController
    include WarehouseReportAuthorization
    include AjaxModalRails::Controller
    include ArelHelper
    include BaseFilters

    before_action :set_report

    def index
      @excel_export = ::ZipCodeReport::DocumentExports::ReportExcelExport.new
      respond_to do |format|
        format.html do
          @pagy, @zip_codes = pagy(@report.zip_codes.order(pc_t[:Zip]))
        end
        format.xlsx do
          filename = "Zip Code Report - #{Time.current.to_fs(:db)}.xlsx"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    private def set_report
      @report = report_class.new(@filter)
    end

    private def report_class
      ZipCodeReport::Report
    end

    private def set_filter
      @filter = filter_class.new(
        user_id: current_user.id,
        start: (Date.current - 1.month).beginning_of_month,
        end: (Date.current - 1.month).end_of_month,
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
