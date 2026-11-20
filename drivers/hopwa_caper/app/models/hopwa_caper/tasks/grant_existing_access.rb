###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# One-shot grant run from db:seed: HOPWA CAPER is no longer part of All HUD
# Reports, so on installs that have run it, everyone who reached it through that
# collection or access group keeps it through a new HOPWA CAPER collection and
# group. Installs with no HOPWA CAPER run grant nobody. The viewer role marks the
# task as done, so later deploys do not re-grant access an admin has since removed.
module HopwaCaper::Tasks
  class GrantExistingAccess
    # Delete this class, its spec, and the call in SeedMaker#run_all. Every install
    # has seeded by then, so the viewer role already exists everywhere.
    TodoOrDie('Delete HopwaCaper::Tasks::GrantExistingAccess one-shot grant', by: Date.new(2027, 4, 1))

    NAME = 'HOPWA CAPER'
    ROLE_NAME = 'HOPWA CAPER Viewer'

    def run!
      return if Role.with_deleted.where(name: ROLE_NAME).exists?

      GrdaWarehouse::WarehouseReports::ReportDefinition.maintain_report_definitions
      ApplicationRecord.transaction do
        role = Role.create!(name: ROLE_NAME, system: false, can_view_assigned_reports: true)
        grant(role) if hopwa_caper_run?
      end
      # Seeding only maintains the data source groups, so without this the first
      # deploy would leave HOPWA CAPER in All HUD Reports.
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

    private def grant(role)
      grant_acl_user_groups(role)
      grant_legacy_users
    end

    private def grant_acl_user_groups(role)
      collection = Collection.create!(name: NAME, collection_type: 'Reports')
      collection.set_viewables({ reports: [definition.id] })
      AccessControl.where(collection_id: Collection.system_collection(:hud_reports).id).distinct.pluck(:user_group_id).each do |user_group_id|
        AccessControl.where(role_id: role.id, collection_id: collection.id, user_group_id: user_group_id).first_or_create!
      end
    end

    private def grant_legacy_users
      group = AccessGroup.where(name: NAME).first_or_create!
      group.set_viewables({ reports: [definition.id] })
      group.add(AccessGroup.system_group(:hud_reports).users.to_a)
    end
  end
end
