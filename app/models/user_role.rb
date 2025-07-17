###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Part of the "legacy" permissions system
class UserRole < ApplicationRecord
  has_paper_trail(
    meta: {
      referenced_user_id: :referenced_user_id,
      referenced_entity_name: :referenced_entity_name,
    },
  )
  acts_as_paranoid

  belongs_to :user, inverse_of: :user_roles
  belongs_to :legacy_user, inverse_of: :user_roles, class_name: 'User', foreign_key: :user_id
  belongs_to :health_user, inverse_of: :user_roles, class_name: 'User', foreign_key: :user_id
  belongs_to :legacy_role, inverse_of: :user_roles, class_name: 'Role', foreign_key: :role_id # TODO: START_ACL remove after ACL migration is complete
  belongs_to :role
  belongs_to :health_role, inverse_of: :user_roles, class_name: 'Role', foreign_key: :role_id

  delegate :administrative?, to: :role

  def referenced_user_id
    user.id
  end

  def referenced_entity_name
    role.name
  end

  def entity_name
    "#{role&.name || 'Unknown Role'}: #{user&.name || 'Unknown User'}"
  end

  def self.describe_changes(version, _changes, _excluded_fields = [])
    user_name = User.find_by(id: version.referenced_user_id)&.name || "User ID #{version.referenced_user_id}"

    if version.event == 'create'
      ["Added user \"#{user_name}\" to role \"#{version.referenced_entity_name}\""]
    else
      ["Removed user \"#{user_name}\" from role \"#{version.referenced_entity_name}\""]
    end
  end
end
