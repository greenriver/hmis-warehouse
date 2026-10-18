###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# WarehouseReportAuthorization for controllers that inherit from ApplicationControllerV2.
# Skip the check for an action with `skip_before_action :authorize_report!, only: ...`; that action
# then needs its own authorize_with.
module WarehouseReportAuthorizationV2
  extend ActiveSupport::Concern

  included do
    before_action :authorize_report!
    helper_method :related_report
  end

  def report_visible?
    current_user.can_view_any_reports? && related_report.viewable_by(current_user).exists?
  end

  # Override when the report definition URL is not this controller's index path.
  # Must respond to `viewable_by`
  def related_report
    url = url_for(action: :index, only_path: true).sub(/^\//, '')
    GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url)
  end

  # useful for determining if a report has been limited to a specific set of projects
  # because of a user's access level
  def set_limited
    all_project_ids = GrdaWarehouse::Hud::Project.order(id: :asc).pluck(:id)
    @visible_projects = GrdaWarehouse::Hud::Project.viewable_by(current_user, permission: :can_view_assigned_reports).order(id: :asc).pluck(:id, :ProjectName).to_h
    @limited = all_project_ids != @visible_projects.keys
  end

  def reload_from_csv
    reload_from_csv_authorization!
    result = Reports::ReloadReportFromCsvService.new(@report).reload!

    if result[:success]
      flash[:notice] = "Report data reloaded successfully. #{result[:reloaded_counts].values.sum} records restored."
    else
      flash[:error] = "Failed to reload report data: #{result[:errors].join(', ')}"
    end

    redirect_to reload_from_csv_redirect_path
  end

  def reload_from_csv_authorization!
    not_authorized! unless current_user.can_view_any_reports?
  end

  def reload_from_csv_redirect_path
    url_for(action: :show, id: @report)
  end

  private def authorize_report!
    mark_authorization_performed!
    not_authorized! unless report_visible?
  end
end
