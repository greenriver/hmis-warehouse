###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class UserGroupMember < ApplicationRecord
  acts_as_paranoid
  has_paper_trail

  belongs_to :user_group, inverse_of: :user_group_members
  belongs_to :user, inverse_of: :user_group_members

  def self.describe_changes(version, changes, _excluded_fields = [])
    # Get the user name from the version's item
    user_name = if version.item
      version.item.user&.name || "User ID #{version.item.user_id}"
    else
      # Parse object_changes if it's a YAML string
      object_changes = if version.object_changes.is_a?(String)
        YAML.safe_load(version.object_changes, permitted_classes: [Time, Date, DateTime])
      else
        version.object_changes
      end
      user_id = object_changes&.dig('user_id', 1) || object_changes&.dig('user_id', 0)

      if user_id
        # Try to find the user by ID (including deleted users)
        user = User.with_deleted.find_by(id: user_id)
        user&.name || "User ID #{user_id}"
      else
        'Unknown User'
      end
    end

    case version.event
    when 'create'
      ["Added user \"#{user_name}\" to group"]
    when 'update'
      changes.map do |field, values|
        from, to = values
        "Changed #{field.humanize.titleize}: from #{render_changed_value(field, from)} to #{render_changed_value(field, to)}"
      end
    when 'destroy'
      ["Removed user \"#{user_name}\" from group"]
    else
      ['Modified user group membership']
    end
  end

  def self.render_changed_value(_field, value)
    return 'nil' if value.nil?

    return value.to_s
  end

  def entity_name
    "#{user_group&.name || 'Unknown Group'}: #{user&.name || 'Unknown User'}"
  end
end
