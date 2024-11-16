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
end
