###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# HMIS uses similar but separate permissions system from the warehouse
# See drivers/hmis/doc/PERMISSIONS.md

class Hmis::UserAccessControl < ApplicationRecord
  acts_as_paranoid
  has_paper_trail

  belongs_to :access_control, class_name: '::Hmis::AccessControl'
  belongs_to :user, class_name: 'Hmis::User'

  def entity_name
    "Access Control #{access_control_id}: #{user&.name || 'Unknown User'}"
  end

  def self.describe_changes(version, _changes, _excluded_fields = [])
    object_changes = if version.object_changes.is_a?(String)
      YAML.safe_load(version.object_changes, permitted_classes: [Time, Date, DateTime])
    else
      version.object_changes
    end
    user_id = object_changes&.dig('user_id', 1) || object_changes&.dig('user_id', 0)
    user_name = if user_id
      Hmis::User.with_deleted.find_by(id: user_id)&.name || "User ID #{user_id}"
    else
      'Unknown User'
    end

    case version.event
    when 'create'
      ["Directly assigned user \"#{user_name}\" to access control"]
    when 'destroy'
      ["Removed direct user assignment for \"#{user_name}\""]
    else
      ['Modified direct user assignment']
    end
  end
end
