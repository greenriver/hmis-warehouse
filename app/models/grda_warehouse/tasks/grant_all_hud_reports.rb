###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# One-time grant run from a migration: every user who could reach HUD reports
# through a role flag keeps that reach once access moves to report definitions
# in collections. Uses a companion role so no existing role's flags change.
module GrdaWarehouse::Tasks
  class GrantAllHudReports
    def run!
      GrdaWarehouse::WarehouseReports::ReportDefinition.maintain_report_definitions
      Collection.maintain_system_groups(group: :reports)
      AccessGroup.maintain_system_groups(group: :reports)
      grant_acl_users
      grant_legacy_users
    end

    private def hud_roles
      Role.where(can_view_all_hud_reports: true).or(Role.where(can_view_own_hud_reports: true))
    end

    private def grant_acl_users
      viewer_role = Role.hud_report_viewer_role
      collection = Collection.system_collection(:hud_reports)
      AccessControl.where(role_id: hud_roles.select(:id)).distinct.pluck(:user_group_id).each do |user_group_id|
        AccessControl.where(role_id: viewer_role.id, collection_id: collection.id, user_group_id: user_group_id).first_or_create!
      end
    end

    private def grant_legacy_users
      user_ids = User.where.not(permission_context: 'acls').joins(:legacy_roles).merge(hud_roles).distinct.pluck(:id)
      AccessGroup.system_group(:hud_reports).add(User.where(id: user_ids).to_a)
    end
  end
end
