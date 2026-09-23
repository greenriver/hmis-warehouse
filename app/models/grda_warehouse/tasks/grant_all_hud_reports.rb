###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# One-shot grant run from db:seed: every user who could reach HUD reports through a
# role flag keeps that reach now that access comes from report definitions in
# collections. Uses a companion role so no existing role's flags change, and the
# presence of that role marks the grant as done so later deploys do not re-grant
# access an admin has since removed. Seeding runs after every database has
# migrated, which a primary migration cannot rely on for the warehouse tables this
# touches.
module GrdaWarehouse::Tasks
  class GrantAllHudReports
    # Delete this class, its spec, and the call in SeedMaker#run_all. Every install
    # has seeded by then, so the companion role already exists everywhere.
    TodoOrDie('Delete GrantAllHudReports one-shot grant', by: Date.new(2027, 1, 15))

    # Companion role for granting HUD report definitions without altering any
    # existing role's flags (project scope would widen otherwise).
    VIEWER_ROLE_NAME = 'HUD Report Viewer'

    def self.viewer_role
      viewer_roles.first_or_create do |role|
        role.can_view_assigned_reports = true
      end
    end

    def self.viewer_roles
      Role.where(system: false, name: VIEWER_ROLE_NAME)
    end

    def run!
      return if self.class.viewer_roles.exists?

      GrdaWarehouse::WarehouseReports::ReportDefinition.maintain_report_definitions
      Collection.maintain_system_groups(group: :reports)
      AccessGroup.maintain_system_groups(group: :reports)
      # The viewer role marks the grant as done, so it must roll back with a failed
      # grant or the next run would skip the users never granted.
      ApplicationRecord.transaction do
        grant_acl_users
        grant_legacy_users
      end
    end

    private def hud_roles
      Role.where(can_view_all_hud_reports: true).or(Role.where(can_view_own_hud_reports: true))
    end

    private def grant_acl_users
      viewer_role = self.class.viewer_role
      collection = Collection.system_collection(:hud_reports)
      AccessControl.where(role_id: hud_roles.select(:id)).distinct.pluck(:user_group_id).each do |user_group_id|
        AccessControl.where(role_id: viewer_role.id, collection_id: collection.id, user_group_id: user_group_id).first_or_create!
      end
    end

    # permission_context is nullable and User#using_acls? treats nil as legacy, so
    # `where.not` alone would drop those users.
    private def grant_legacy_users
      legacy_users = User.where(permission_context: nil).or(User.where.not(permission_context: 'acls'))
      user_ids = legacy_users.joins(:legacy_roles).merge(hud_roles).distinct.pluck(:id)
      AccessGroup.system_group(:hud_reports).add(User.where(id: user_ids).to_a)
    end
  end
end
