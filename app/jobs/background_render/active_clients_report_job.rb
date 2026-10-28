###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class BackgroundRender::ActiveClientsReportJob < BackgroundRenderJob
  def render_html(filter:, user_id:, page: nil)
    current_user = User.find(user_id)
    # matches ClientDetailReports#set_filter so the counts agree with the page's filter
    @filter = ::Filters::FilterBase.new(
      user_id: user_id,
      enforce_one_year_range: false,
      project_type_codes: [],
    ).set_from_params(JSON.parse(filter).with_indifferent_access[:filters])
    @report = report_source.new(filter: @filter, user: current_user)
    WarehouseReports::ClientDetails::ActivesController.render(
      partial: 'report',
      assigns: {
        filter: @filter,
        report: @report,
        limited: limited(current_user),
        visible_projects: visible_projects(current_user),
        page: page,
      },
      locals: {
        current_user: current_user,
      },
    )
  end

  def visible_projects(user)
    GrdaWarehouse::Hud::Project.viewable_by(user, permission: :can_view_assigned_reports).order(id: :asc).pluck(:id, :ProjectName).to_h
  end

  def limited(user)
    all_project_ids = GrdaWarehouse::Hud::Project.order(id: :asc).pluck(:id)
    all_project_ids != visible_projects(user).keys
  end

  def report_source
    ActiveClientReport
  end
end
