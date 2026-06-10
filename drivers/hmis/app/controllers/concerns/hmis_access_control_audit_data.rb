###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisAccessControlAuditData
  extend ActiveSupport::Concern
  include HmisAuditHistory

  def hmis_access_control_audit_preloads
    [
      :user_group,
      :role,
      :access_group,
      :user_access_controls,
      { user_group: :user_group_members },
      { access_group: :group_viewable_entities },
    ]
  end

  def build_histories
    access_controls = Hmis::AccessControl.with_deleted.preload(*hmis_access_control_audit_preloads)
    Audit::Versions.build_batch(access_controls, hmis_access_control_component_config)
  end

  def build_data(histories)
    histories.flat_map do |history|
      versions = history.version_array
      history.wrap_display_versions(versions).map do |version|
        {
          history: history,
          version: version,
        }
      end
    end.sort_by { |h| h[:version]&.created_at }.reverse
  end
end
