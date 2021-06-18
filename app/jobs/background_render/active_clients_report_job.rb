class BackgroundRender::ActiveClientsReportJob < BackgroundRenderJob

  def render_html(filter:, user_id:)
    current_user = User.find(user_id)
    @filter = ::Filters::FilterBase.new(user_id: user_id).set_from_params(JSON.parse(filter).with_indifferent_access[:filters])
    @report = report_source.new(filter: @filter, user: current_user)
    WarehouseReports::ClientDetails::ActivesController.render(
      partial: 'report',
      assigns: {
        filter: @filter,
        report: @report,
      },
      locals: {
        current_user: current_user,
      },
    )
  end

  def report_source
    ActiveClientReport
  end
end
