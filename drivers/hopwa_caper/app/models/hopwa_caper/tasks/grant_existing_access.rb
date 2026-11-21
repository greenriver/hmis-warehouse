###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# One-time TaskQueue task: HOPWA CAPER is no longer part of All HUD Reports, so on
# installs that have run it, everyone who reached it through that collection or
# access group keeps it through a new HOPWA CAPER collection and group. Installs
# with no HOPWA CAPER run grant nobody.
module HopwaCaper::Tasks
  class GrantExistingAccess
    # Delete this class, its spec, and its TaskQueue registration in the HOPWA CAPER
    # initializer. Every install has run the task by then.
    TodoOrDie('Delete HopwaCaper::Tasks::GrantExistingAccess one-time grant', by: Date.new(2027, 4, 1))

    NAME = 'HOPWA CAPER'
    ROLE_NAME = 'HOPWA CAPER Viewer'

    def run!
      GrdaWarehouse::WarehouseReports::ReportDefinition.maintain_report_definitions
      # The role exists only after a committed grant, so a Delayed Job retry or a
      # re-queued key skips the grant instead of duplicating its records.
      if hopwa_caper_run? && !Role.with_deleted.exists?(name: ROLE_NAME)
        ApplicationRecord.transaction do
          # Two separate connections; nesting makes a failed grant roll back both.
          GrdaWarehouseBase.transaction { grant }
        end
      end
      # Seeding maintains only the data source collections, so without this ACL
      # users would keep HOPWA CAPER through All HUD Reports.
      Collection.maintain_system_groups(group: :reports)
      AccessGroup.maintain_system_groups(group: :reports)
      User.clear_cached_permissions
    end

    private def hopwa_caper_run?
      titles = HopwaCaper::BaseController.new.possible_generator_classes.values.map(&:title)
      HudReports::ReportInstance.where(report_name: titles).exists?
    end

    private def definition
      GrdaWarehouse::WarehouseReports::ReportDefinition.find_by!(url: GrdaWarehouse::WarehouseReports::ReportDefinition.hud_url(:hopwa_capers))
    end

    private def grant
      grant_acl_user_groups(Role.create!(name: ROLE_NAME, system: false, can_view_assigned_reports: true))
      grant_legacy_users
    end

    private def grant_acl_user_groups(role)
      collection = Collection.create!(name: NAME, collection_type: 'Reports')
      collection.set_viewables({ reports: [definition.id] })
      report_user_group_ids.each do |user_group_id|
        AccessControl.where(role_id: role.id, collection_id: collection.id, user_group_id: user_group_id).first_or_create!
      end
    end

    private def report_user_group_ids
      AccessControl.
        joins(:role).
        merge(Role.where(can_view_assigned_reports: true)).
        where(collection_id: Collection.system_collection(:hud_reports).id).
        distinct.
        pluck(:user_group_id)
    end

    private def grant_legacy_users
      group = AccessGroup.create!(name: NAME)
      group.set_viewables({ reports: [definition.id] })
      group.add(AccessGroup.system_group(:hud_reports).users.to_a)
    end
  end
end
