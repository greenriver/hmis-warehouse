###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Part of the "legacy" role-based permissions system
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

  def self.describe_changes(version, _changes)
    if version.event == 'create'
      ["Added role #{version.referenced_entity_name}"]
    else
      ["Removed role #{version.referenced_entity_name}"]
    end
  end
end
