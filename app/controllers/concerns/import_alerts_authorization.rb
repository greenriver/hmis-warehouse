###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Access rules for a data source's import alert configuration: import thresholds, CSV
# monitors, and the notification recipients of each.
#
# Anyone who can view the data source may see the configuration (notification emails link
# here). Changing it requires edit rights on this data source, or the warehouse-wide alerts
# permission (the admin alerts page links here for every data source).
module ImportAlertsAuthorization
  extend ActiveSupport::Concern

  READ_ACTIONS = ['show', 'index'].freeze

  private def require_can_edit_data_sources_or_warehouse_alerts!
    not_authorized! unless can_edit_data_sources? || can_edit_warehouse_alerts?
  end

  private def import_alerts_data_source_scope
    viewable = GrdaWarehouse::DataSource.viewable_by(current_user, permission: :can_view_projects)
    return viewable if action_name.in?(READ_ACTIONS)
    return viewable if can_edit_warehouse_alerts?

    GrdaWarehouse::DataSource.editable_by(current_user)
  end
end
