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

  private def authorize_report!
    not_authorized! unless report_visible?

    authorization_performed!
  end
end
