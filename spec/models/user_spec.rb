# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { create :user }
  let(:agency) { create :agency }

  describe 'validations' do
    context 'if email missing' do
      let(:user) { build :user, email: nil }

      it 'is invalid' do
        expect(user).to be_invalid
      end
    end
  end

  describe 'invitation handling' do
    context 'when user has an outstanding invitation' do
      before do
        User.invite!({ email: 'unconfirmed@example.com', first_name: 'Unconfirmed', last_name: 'User', agency_id: agency.id }, User.system_user)
        @user = User.last
      end

      describe 'confirming a user' do
        it 'adds an error and returns false' do
          expect(@user.invitation_token).to be_present
          expect(@user.invitation_status).to eq(:pending_confirmation)
          expect(@user.confirm).to be false
          expect(@user.confirmed?).to be false
          expect(@user.errors[:email]).to include('There is an open invitation for this account.')
        end

        it 'Refuses to accept the invitation after the invitation has expired' do
          travel_to(@user.invitation_due_at + 1.weeks) do
            expect do
              User.accept_invitation!(invitation_token: @user.invitation_token)
            end.to not_change(@user, :invitation_status)
          end
        end

        it 'Refuses to confirm email after the invitation has expired' do
          travel_to(@user.invitation_due_at + 1.weeks) do
            expect(@user.invitation_token).to be_present
            expect(@user.invitation_status).to eq(:invitation_expired)
            expect(@user.confirm).to be false
            expect(@user.confirmed?).to be false
            expect(@user.errors[:email]).to include('There is an open invitation for this account.')
          end
        end
      end

      describe 'after accepting the invitation and confirming the user' do
        before do
          @user.accept_invitation!
          @user.confirm
        end

        it 'confirming a user returns true' do
          expect(@user.confirmed?).to be true
        end
      end
    end
  end

  describe '.text_search' do
    let!(:user1) { create(:user, first_name: 'Alice', last_name: 'Smith', email: 'alice.smith@example.com') }
    let!(:user2) { create(:user, first_name: 'Alicea', last_name: 'Smythe', email: 'alicia.smythe@example.com') }
    let!(:user3) { create(:user, first_name: 'Bob', last_name: 'Jones', email: 'bob.jones@example.com') }

    it 'finds users by first name' do
      results = User.text_search('Alice')
      expect(results).to include(user1)
      expect(results).not_to include(user3)
    end

    it 'finds users by last name' do
      results = User.text_search('Jones')
      expect(results).to include(user3)
      expect(results).not_to include(user1)
    end

    it 'finds users by email' do
      results = User.text_search('alice.smith@example.com')
      expect(results).to include(user1)
      expect(results).not_to include(user3)
    end

    it 'returns none for no match' do
      results = User.text_search('Nonexistent')
      expect(results).to be_empty
    end

    it 'orders results by best match when sort_by_best_match is true' do
      results = User.text_search('Alice', sort_by_best_match: true)
      expect(results.first).to eq(user1)
      expect(results).to include(user2)
      expect(results).not_to include(user3)
    end
  end
end
