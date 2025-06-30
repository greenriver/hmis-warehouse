###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module AuditHistory
  extend ActiveSupport::Concern

  private

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

  def collection_audit_config
    {
      referenced_models: [
        { class: AccessControl, association: :access_controls },
        { class: GrdaWarehouse::GroupViewableEntity, association: :group_viewable_entities },
      ],
      excluded_fields: ['updated_at'],
    }
  end

  def role_audit_config
    {
      referenced_models: [
        { class: AccessControl, association: :access_controls },
        { class: UserRole, association: :user_roles },
      ],
      excluded_fields: ['updated_at'],
    }
  end

  def user_group_audit_config
    {
      referenced_models: [
        { class: AccessControl, association: :access_controls },
        { class: UserGroupMember, association: :user_group_members },
      ],
      excluded_fields: ['updated_at'],
    }
  end

  # Generate CSV for standard audit exports
  def generate_audit_csv(versions, history, include_headers: true)
    require 'csv'

    CSV.generate(headers: include_headers) do |csv|
      csv << ['Date Changed', 'Editor', 'Entity Type', 'Entity Name', 'Changed Entity Type', 'Changed Entity Name', 'Event', 'Changes'] if include_headers

      history.wrap_display_versions(versions).each do |item|
        changes_text = if item.error
          'Load error - Sorry, we couldn\'t load the change details for this version.'
        elsif item.changes
          item.changes.join('; ')
        else
          'N/A'
        end

        editor_text = if item.username
          if item.impersonating
            "#{item.username} (Impersonating #{item.impersonating})"
          else
            item.username
          end
        else
          'N/A'
        end

        csv << [
          item.created_at.to_fs,
          editor_text,
          history.record.class.name,
          history.record.name,
          item.entity_name,
          item.entity_display_name,
          item.event.titleize,
          changes_text,
        ]
      end
    end
  end
end
