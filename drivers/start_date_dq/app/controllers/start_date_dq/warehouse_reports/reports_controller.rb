###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module StartDateDq::WarehouseReports
  class ReportsController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    include BaseFilters
    include Filter::FilterScopes

    before_action :set_report
    before_action :set_excel_export

    def index
      respond_to do |format|
        format.html do
          if params[:filter].present?
            data = @report.data
            @pagy, @enrollments = pagy(data, items: 50)
          end
        end
        format.xlsx do
          # See drivers/start_date_dq/app/models/start_date_dq/document_exports/start_date_dq_excel_export.rb
        end
      end
    end

    private def set_excel_export
      @excel_export = StartDateDq::DocumentExports::StartDateDqExcelExport.new
    end

    private def set_report
      @filter = filter_class.new(
        user_id: current_user.id,
        default_start: Date.current - 3.months,
        default_end: Date.current,
        dates_to_compare: :date_to_street_to_entry,
      ).set_from_params(filter_params)
      @report = report_class.new(current_user.id, @filter)
    end

    private def report_class
      StartDateDq::Report
    end

    def filter_params
      site_coc_codes = GrdaWarehouse::Config.get(:site_coc_codes).presence&.split(/,\s*/)
      return { coc_codes: site_coc_codes } unless params[:filter].present?

      params.require(:filter).permit(filter_class.new.known_params)
    end
    helper_method :filter_params

    private def filter_class
      ::Filters::FilterBase
    end
  end
end
