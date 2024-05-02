###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# == AppResourceMonitor::AppInspector
#
# Utility to collect and report app usage
#
class AppResourceMonitor::AppInspector
  def self.utilization_stats
    [
      {
        active_users: User.where(active: true).count,
        hud_clients: GrdaWarehouse::Hud::Client.source.count,
        hud_enrollments: GrdaWarehouse::Hud::Enrollment.count,
        hud_projects: GrdaWarehouse::Hud::Project.count,
        hud_reports: HudReports::ReportInstance.count,
        simple_reports: SimpleReports::ReportInstance.count,
      },
    ]
  end

  # user activity within range
  def self.activity_stats(range:)
    [
      {
        starts_at: range.begin&.to_fs(:db),
        ends_at: range.end&.to_fs(:db),
        distinct_warehouse_users: ActivityLog.where(created_at: range).distinct.count(:user_id),
        distinct_hmis_users: Hmis::ActivityLog.where(created_at: range).distinct.count(:user_id),
      },
    ]
  end
end
