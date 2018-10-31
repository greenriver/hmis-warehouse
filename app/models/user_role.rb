class UserRole < ActiveRecord::Base
  has_paper_trail(
      meta: { referenced_user_id: :referenced_user_id, referenced_entity_name: :referenced_entity_name }
  )
  acts_as_paranoid

  belongs_to :user, inverse_of: :user_roles
  belongs_to :role, inverse_of: :user_roles

  def referenced_user_id
    user.id
  end

  def referenced_entity_name
    role.name
  end

  def self.describe_changes(version, changes)
    if version.event == 'create'
      [ "Added role #{version.referenced_entity_name}" ]
    else
      [ "Removed role #{version.referenced_entity_name}" ]
    end
  end
end
