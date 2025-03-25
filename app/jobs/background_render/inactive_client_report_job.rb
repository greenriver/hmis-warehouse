###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class BackgroundRender::InactiveClientReportJob < BackgroundRenderJob
  include Pagy::Backend

  def params
    @params ||= {}
  end

  def render_html(filters:, user_id:, page:)
    current_user = User.find(user_id)
    @filter = ::Filters::FilterBase.new(user_id: user_id).set_from_params(JSON.parse(filters).with_indifferent_access)
    set_report
    @pagy, @clients = pagy(@report.clients.order(:last_name, :first_name), page: page, params: @filter.for_params)
    InactiveClientReport::WarehouseReports::ReportsController.render(
      partial: 'report',
      assigns: {
        excel_export: ::InactiveClientReport::DocumentExports::ReportExcelExport.new,
        report: @report,
        filter: @filter,
        clients: @clients,
        pagy: @pagy,
      },
      locals: {
        current_user: current_user,
      },
    )
  end

  private def set_report
    @report = report_class.new(@filter)
  end

  private def report_class
    InactiveClientReport::Report
  end
end
