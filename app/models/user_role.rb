class UserRole < ActiveRecord::Base

  belongs_to :user, inverse_of: :user_roles
  belongs_to :role, inverse_of: :user_roles

end
