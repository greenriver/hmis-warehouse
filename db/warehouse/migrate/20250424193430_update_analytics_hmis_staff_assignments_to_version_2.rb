class UpdateAnalyticsHmisStaffAssignmentsToVersion2 < ActiveRecord::Migration[7.0]
  def change
    update_view "analytics.hmis_staff_assignments", version: 2, revert_to_version: 1
  end
end
