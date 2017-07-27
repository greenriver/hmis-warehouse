require 'rails_helper'

RSpec.describe User, type: :model do

  let(:user) { create :user }

  describe 'validations' do
    context 'if email missing' do
      let(:user) { build :user, email: nil }

      it 'is invalid' do
        expect( user ).to be_invalid
      end
    end
  end
end
