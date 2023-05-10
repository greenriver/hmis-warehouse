require 'rails_helper'

RSpec.describe UserGroup, type: :model do
  let(:user_group) { create :user_group }
  let(:user_one) { create :user }
  let(:user_two) { create :user }
  let(:user_three) { create :user }

  describe 'A Group' do
    it 'provides methods to manage membership' do
      # starts empty
      expect(user_group.users.length).to be 0

      # can add a single user
      user_group.add(user_one)
      expect(user_group.users.reload.length).to be 1

      # can add an array of users
      user_group.add([user_two, user_three])
      expect(user_group.users.reload.length).to be 3

      # gracefully skips adding any existing users
      user_group.add([user_two, user_three])
      expect(user_group.users.reload.length).to be 3

      # can remove a single user
      user_group.remove(user_three)
      expect(user_group.users.reload.length).to be 2

      # can remove multiple users
      user_group.remove([user_one, user_two])
      expect(user_group.users.reload.length).to be 0

      # gracefully handles removing non-existant users
      user_group.remove([user_one, user_two])
      expect(user_group.users.reload.length).to be 0

      # can re-add previously removed users
      user_group.add([user_one, user_two])
      expect(user_group.users.reload.length).to be 2
    end
  end
end
