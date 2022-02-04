###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class UserRole < ApplicationRecord
  has_paper_trail(
    meta: {
      referenced_user_id: :referenced_user_id,
      referenced_entity_name: :referenced_entity_name,
    },
  )
  acts_as_paranoid

  belongs_to :user, inverse_of: :user_roles
  belongs_to :role, inverse_of: :user_roles

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
