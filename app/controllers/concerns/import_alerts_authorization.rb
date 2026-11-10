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

  included do
    helper_method :can_edit_import_alerts?
  end

  # Whether the current user may change this data source's alert configuration. Views use it
  # to hide the edit controls from read-only viewers. Mirrors the write-action rule in
  # #import_alerts_data_source_scope.
  private def can_edit_import_alerts?
    return @can_edit_import_alerts if defined?(@can_edit_import_alerts)

    @can_edit_import_alerts = if can_edit_warehouse_alerts?
      true
    elsif can_edit_data_sources?
      GrdaWarehouse::DataSource.editable_by(current_user).exists?(id: data_source.id)
    else
      false
    end
  end

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
