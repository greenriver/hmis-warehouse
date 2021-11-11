###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module TxClientReports::WarehouseReports
  class AttachmentThreeClientDataReportsController < ApplicationController
    include AjaxModalRails::Controller
    include WarehouseReportAuthorization
    include ArelHelper

    before_action :filter
    before_action :report

    def index
      @rows = @report.rows
      respond_to do |format|
        format.html do
          flash[:error] = 'You must select a project' if params[:commit].present? && ! @show_report
          @pagy, @rows = pagy_array(@rows)
        end
        format.xlsx do
          filename = "Attachment III - #{Time.current.to_s(:db)}.xlsx"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    private def filter
      @filter = ::Filters::FilterBase.new(user_id: current_user.id)
      @filter.update(report_params.merge({ project_type_codes: [] }))
      @show_report = @filter.project_ids.present?
    end

    private def report
      @report = TxClientReports::AttachmentThreeReport.new(@filter)
    end

    private def report_params
      return {} unless params[:filters].present?

      report_params = params.require(:filters).permit(
        :start,
        :end,
        :project_ids,
        project_ids: [],
      )

      report_params[:project_ids] = Array.wrap(report_params[:project_ids]) if report_params[:project_ids].present?
      report_params
    end
  end
end
