###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module AccessControlAuditData
  extend ActiveSupport::Concern
  include AuditHistory

  def access_control_audit_preloads
    [
      :user_group,
      :role,
      :collection,
      { user_group: :user_group_members },
      { role: :user_roles },
      { collection: :group_viewable_entities },
    ]
  end

  def build_histories(user)
    # Preload access controls with their associations
    access_controls = AccessControl.visible_to(user).
      preload(*access_control_audit_preloads)

    # Use the optimized batch creation method
    Audit::Versions.build_batch(access_controls, access_control_component_config)
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

  def access_control_component_config
    {
      related_models: [
        { class: UserGroup, association: :user_group },
        { class: Role, association: :role },
        { class: Collection, association: :collection },
      ],
      nested_models: [
        { class: UserGroupMember, parent_association: :user_group, nested_association: :user_group_members },
        { class: UserRole, parent_association: :role, nested_association: :user_roles },
        { class: GrdaWarehouse::GroupViewableEntity, parent_association: :collection, nested_association: :group_viewable_entities },
      ],
      include_self: false,
      excluded_fields: ['updated_at'],
    }
  end
end
