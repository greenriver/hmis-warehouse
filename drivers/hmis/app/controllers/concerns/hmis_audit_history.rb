###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisAuditHistory
  extend ActiveSupport::Concern
  include AuditHistory

  private

  def hmis_access_control_component_config
    {
      related_models: [
        { class: Hmis::UserGroup, association: :user_group },
        { class: Hmis::Role, association: :role },
        { class: Hmis::AccessGroup, association: :access_group },
      ],
      nested_models: [
        { class: Hmis::UserGroupMember, parent_association: :user_group, nested_association: :user_group_members },
        { class: Hmis::GroupViewableEntity, parent_association: :access_group, nested_association: :group_viewable_entities },
      ],
      referenced_models: [
        { class: Hmis::UserAccessControl, association: :user_access_controls },
      ],
      excluded_fields: ['updated_at'],
    }
  end

  def hmis_group_audit_config
    {
      referenced_models: [
        { class: Hmis::AccessControl, association: :access_controls },
        { class: Hmis::GroupViewableEntity, association: :group_viewable_entities },
      ],
      excluded_fields: ['updated_at'],
    }
  end

  def hmis_role_audit_config
    {
      referenced_models: [
        { class: Hmis::AccessControl, association: :access_controls },
      ],
      excluded_fields: ['updated_at'],
    }
  end

  def hmis_user_group_audit_config
    {
      referenced_models: [
        { class: Hmis::AccessControl, association: :access_controls },
        { class: Hmis::UserGroupMember, association: :user_group_members },
      ],
      excluded_fields: ['updated_at'],
    }
  end
end
