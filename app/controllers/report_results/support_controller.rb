###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module ReportResults
  class SupportController < ApplicationController
    include AjaxModalRails::Controller
    include WarehouseReportAuthorization
    before_action :set_report, only: [:index]
    before_action :set_report_result, only: [:index]

    # Requires a key to fetch the appropriate chunk of support
    def index
      raise 'Key required' if params[:key].blank?

      key = params[:key].to_s
      support = @result.support
      @data = support[key]
      respond_to do |format|
        format.xlsx do
          render xlsx: 'index', filename: "support-#{key.parameterize}.xlsx"
        end
        format.html {}
      end
    end

    # viewable_by narrows to the user's own results unless they can view all HUD reports.
    def set_report_result
      @result = @report.report_results.viewable_by(current_user).find(params[:report_result_id].to_i)
    end

    def set_report
      @report = Report.find(params[:report_id].to_i)
    end

    def related_report
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: Report.find(params[:report_id].to_i).report_definition_url)
    end
  end
end
