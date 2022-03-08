###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module TxClientReports::WarehouseReports
  class AttachmentThreeClientDataReportsController < ApplicationController
    include AjaxModalRails::Controller
    include WarehouseReportAuthorization
    include ArelHelper

    before_action :filter

    def index
      @rows = report.rows
      respond_to do |format|
        format.html do
          show_validations
          @pagy, @rows = pagy_array(@rows)
        end
        format.xlsx do
          filename = "Attachment III - #{Time.current.to_s(:db)}.xlsx"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    private def show_validations
      return unless params[:commit].present?

      flash[:error] = 'You must select a project or project group' unless show_report?
    end

    private def filter
      @filter ||= begin
        f = ::Filters::FilterBase.new(user_id: current_user.id)
        f.update(report_params.merge({ project_type_codes: [] }))
        f
      end
    end

    private def show_report?
      filter.project_ids.present? || filter.project_group_ids.present?
    end
    helper_method :show_report?

    private def report
      @report ||= TxClientReports::AttachmentThreeReport.new(@filter)
    end
    helper_method :report

    private def report_params
      return {} unless params[:filters].present?

      report_params = params.require(:filters).permit(
        :start,
        :end,
        :project_ids,
        project_ids: [],
        project_group_ids: [],
      )

      report_params[:project_ids] = Array.wrap(report_params[:project_ids])
      report_params
    end
  end
end
