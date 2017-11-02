module HudReports::Ahar
  class Fy2017Controller < ApplicationController
    before_action :require_can_view_reports!
    before_action :set_report_result, :set_support

    def support
      category = params[:category]
      label = params[:label]
      respond_to do |format|
        format.xlsx do
          render xlsx: :support, filename: "support-#{category}-#{label}.xlsx"
        end
        format.html {}
      end
    end

    def set_report_result
      @report_result = ReportResult.find(params[:report_result_id].to_i)
    end

    def set_support
      @support = @report_result.support.try(:[], params[:category]).try(:[], params[:label])
    end
  end
end