class AddCanViewAllReportsUsersToGroups < ActiveRecord::Migration[5.2]
  def up
    if Role.permissions.include?(:can_view_all_reports)
      all_hmis_reports = AccessGroup.where(name: AccessGroup::ALL_HMIS_REPORTS_GROUP_NAME).first_or_create
      all_health_reports = AccessGroup.where(name: AccessGroup::ALL_HEALTH_REPORTS_GROUP_NAME).first_or_create

      User.can_view_all_reports.find_each do |user|
        all_hmis_reports.add(user)
        all_health_reports.add(user)
      end

      Role.where(can_view_all_reports: true).update_all(
        can_view_all_reports: false,
        can_view_assigned_reports: true,
      )
    end
  end
end
