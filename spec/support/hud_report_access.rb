###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudReportAccess
  include AccessControlSetup

  # HUD report specs used to pass on a role flag alone; the gate is now the
  # report definition sitting in one of the user's collections.
  def grant_hud_report(user, url, role: nil)
    GrdaWarehouse::WarehouseReports::ReportDefinition.maintain_report_definitions
    definition = GrdaWarehouse::WarehouseReports::ReportDefinition.find_by!(url: url)
    role ||= create(:role, can_view_assigned_reports: true)
    if user.using_acls?
      collection = create(:collection, collection_type: 'Reports')
      collection.set_viewables(reports: [definition.id])
      setup_access_control(user, role, collection)
    else
      user.legacy_roles << role
      # Not User#add_viewable: that refreshes project-id caches, which memoizes the
      # permission hash on this instance and hides later role changes from specs.
      user.access_group.add_viewable(definition)
    end
  end
end
