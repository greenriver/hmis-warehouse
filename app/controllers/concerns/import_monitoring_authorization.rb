###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Access checks for a data source's import monitoring configuration: import thresholds, CSV
# monitors, and the notification recipients of each.
#
# Including controllers must define `data_source`, loading the record with
# `DataSource.viewable_by` and memoizing it. Anyone who can view the data source may see the
# configuration (alert emails link here); changing it requires the matching DataSourcePolicy check.
# Views ask `data_source_policy` directly to hide the edit controls from read-only viewers.
module ImportMonitoringAuthorization
  extend ActiveSupport::Concern

  included do
    helper_method :data_source_policy
  end

  private def data_source_policy
    current_user.policy_for(data_source)
  end

  private def require_can_edit_import_thresholds!
    not_authorized! unless data_source_policy.can_edit_import_thresholds?
  end

  private def require_can_edit_import_csv_monitors!
    not_authorized! unless data_source_policy.can_edit_import_csv_monitors?
  end

  private def require_can_edit_import_alert_recipients!
    not_authorized! unless data_source_policy.can_edit_import_alert_recipients?
  end
end
