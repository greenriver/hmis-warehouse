require 'rails_helper'

RSpec.describe Role, type: :model do
  let(:role) { create :role }
  let(:user_one) { create :user }
  let(:user_two) { create :user }
  let(:user_three) { create :user }

  describe 'A Role' do
    it 'provides methods to manage membership' do
      # starts empty
      expect(role.users.length).to be 0

      # can add a single user
      role.add(user_one)
      expect(role.users.length).to be 1
      expect(user_one.roles.length).to be 1

      # can add an array of users
      role.add([user_two, user_three])
      expect(role.users.length).to be 3

      # gracefully skips adding any existing users
      role.add([user_two, user_three])
      expect(role.users.length).to be 3

      # can remove a single user
      role.remove(user_three)
      expect(role.users.length).to be 2

      # can remove multiple users
      role.remove([user_one, user_two])
      expect(role.users.length).to be 0

      # gracefully handles removing non-existant users
      role.remove([user_one, user_two])
      expect(role.users.length).to be 0

      # can re-add previously removed users
      role.add([user_one, user_two])
      expect(role.users.length).to be 2
    end
  end
end
