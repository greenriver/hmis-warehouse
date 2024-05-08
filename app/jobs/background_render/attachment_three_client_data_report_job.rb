###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class BackgroundRender::AttachmentThreeClientDataReportJob < BackgroundRenderJob
  include Pagy::Backend

  def params
    @params ||= {}
  end

  def render_html(filters:, user_id:, page:)
    current_user = User.find(user_id)
    @filter = ::Filters::FilterBase.new(user_id: user_id).set_from_params(JSON.parse(filters).with_indifferent_access)
    set_report
    @rows = @report.rows
    @pagy, @rows = pagy_array(@rows, page: page, params: @filter.for_params)
    TxClientReports::WarehouseReports::AttachmentThreeClientDataReportsController.render(
      partial: 'report',
      assigns: {
        report: @report,
        section: @section,
        filter: @filter,
        can_view_projects: current_user.can_view_projects?,
        rows: @rows,
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
    TxClientReports::AttachmentThreeReport
  end
end
