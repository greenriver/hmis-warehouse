require 'rails_helper'

RSpec.describe AccessGroup, type: :model do
  let(:access_group) { create :access_group }
  let(:user_one) { create :user }
  let(:user_two) { create :user }
  let(:user_three) { create :user }

  describe 'A Group' do
    it 'provides methods to manage membership' do
      # starts empty
      expect(access_group.users.length).to be 0

      # can add a single user
      access_group.add(user_one)
      expect(access_group.users.length).to be 1

      # can add an array of users
      access_group.add([user_two, user_three])
      expect(access_group.users.length).to be 3

      # gracefully skips adding any existing users
      access_group.add([user_two, user_three])
      expect(access_group.users.length).to be 3

      # can remove a single user
      access_group.remove(user_three)
      expect(access_group.users.length).to be 2

      # can remove multiple users
      access_group.remove([user_one, user_two])
      expect(access_group.users.length).to be 0

      # gracefully handles removing non-existant users
      access_group.remove([user_one, user_two])
      expect(access_group.users.length).to be 0
    end
  end
end
