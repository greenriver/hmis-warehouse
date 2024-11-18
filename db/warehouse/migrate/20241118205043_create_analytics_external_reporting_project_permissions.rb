class CreateAnalyticsExternalReportingProjectPermissions < ActiveRecord::Migration[7.0]
  def change
    create_view "analytics.external_reporting_project_permissions"
  end
end
