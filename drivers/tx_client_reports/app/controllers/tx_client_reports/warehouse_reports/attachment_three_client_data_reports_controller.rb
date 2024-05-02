###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module TxClientReports::WarehouseReports
  class AttachmentThreeClientDataReportsController < ApplicationController
    include AjaxModalRails::Controller
    include WarehouseReportAuthorization
    include ArelHelper
    extend BackgroundRenderAction

    before_action :filter

    background_render_action(:render_section, ::BackgroundRender::AttachmentThreeClientDataReportJob) do
      {
        filters: params[:filter].to_json,
        user_id: current_user.id,
        page: params[:query_string][:page],
      }
    end

    def index
      @can_view_projects = current_user.can_view_projects?
      @excel_export = TxClientReports::AttachmentThreeReportExports::AttachmentThreeReportExcelExport.new
      respond_to do |format|
        format.html do
          show_validations
        end
        format.xlsx do
          @rows = report.rows
          filename = "Attachment III - #{Time.current.to_s(:db)}.xlsx"
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    def data
      @rows = report.rows
      @pagy, @rows = pagy_array(@rows)
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
