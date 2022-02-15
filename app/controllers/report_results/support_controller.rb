###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ReportResults
  class SupportController < ApplicationController
    include AjaxModalRails::Controller
    before_action :require_can_view_hud_reports!
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

    def set_report_result
      @result = ReportResult.find(params[:report_result_id].to_i)
    end

    def set_report
      @report = Report.find(params[:report_id].to_i)
    end
  end
end
