###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Access checks for a data source's import alert configuration: import thresholds, CSV
# monitors, and the notification recipients of each.
#
# Including controllers must define `data_source`, loading the record with
# `DataSource.viewable_by` and memoizing it. Anyone who can view the data source may see
# the configuration (alert emails link here); changing it requires
# DataSourcePolicy#can_edit_import_alerts?.
module ImportAlertsAuthorization
  extend ActiveSupport::Concern

  included do
    helper_method :data_source_policy
    helper_method :can_edit_import_alerts?
  end

  private def data_source_policy
    current_user.policy_for(data_source)
  end

  # Views use it to hide the edit controls from read-only viewers.
  private def can_edit_import_alerts?
    data_source_policy.can_edit_import_alerts?
  end

  private def require_can_edit_import_alerts!
    not_authorized! unless can_edit_import_alerts?
  end
end
