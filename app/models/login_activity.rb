class LoginActivity < ApplicationRecord
  belongs_to :user, polymorphic: true
end
