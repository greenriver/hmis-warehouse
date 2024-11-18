class CreateAnalyticsExternalReportingCohortPermissions < ActiveRecord::Migration[7.0]
  def change
    create_view 'analytics.external_reporting_cohort_permissions'
  end
end
