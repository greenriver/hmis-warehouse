###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReportAuthorization
  extend ActiveSupport::Concern
  included do
    before_action :report_visible?
    before_action :require_can_view_any_reports!

    def report_visible?
      return true if related_report.viewable_by(current_user).exists?

      not_authorized!
    end

    # Override as necessary in the specific controller
    # Eventually, this should reference a method on the report model
    # Must respond to `viewable_by`
    def related_report
      url = url_for(action: :index, only_path: true).sub(%r{^/}, '')
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url)
    end
    helper_method :related_report

    # useful for determining if a report has been limited to a specific set of projects
    # because of a user's access level
    def set_limited
      all_project_ids = GrdaWarehouse::Hud::Project.order(id: :asc).pluck(:id)
      @visible_projects = GrdaWarehouse::Hud::Project.viewable_by(current_user).order(id: :asc).pluck(:id, :ProjectName).to_h
      @limited = all_project_ids != @visible_projects.keys
    end
  end
end
