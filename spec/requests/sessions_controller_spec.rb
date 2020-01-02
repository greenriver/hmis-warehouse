require 'rails_helper'

RSpec.describe Users::SessionsController, type: :request do
  let(:user) { create :user }
  let(:email)  { ActionMailer::Base.deliveries.last }

  describe 'Successful login' do
    before(:each) do
      post user_session_path(user: { email: user.email, password: user.password })
      # post user_session_path(email: user.email, password: 'incorrect')
    end

    it 'user failed_attempts should not increment' do
      expect(user.reload.failed_attempts).to eq 0
    end
  end

  describe 'Un-successful login' do
    before(:each) do
      post user_session_path(user: { email: user.email, password: 'incorrect' })
      # post user_session_path(email: user.email, password: 'incorrect')
    end

    # FIXME: we need to double the number of attempts because of a bug in devise 2FA that
    # hasn't been fixed yet https://github.com/tinfoil/devise-two-factor/pull/136
    # https://github.com/tinfoil/devise-two-factor/pull/130
    it 'user failed_attempts should increment' do
      expect(user.reload.failed_attempts).to eq 2
    end

    describe 'followed by a successful login' do
      before(:each) do
        post user_session_path(user: { email: user.email, password: user.password })
        # post user_session_path(email: user.email, password: 'incorrect')
      end

      it 'user failed_attempts should return to 0' do
        expect(user.reload.failed_attempts).to eq 0
      end
    end
  end

  describe 'Account locked after 9 un-successful logins' do
    before(:each) do
      # FIXME: this should be (Devise.maximum_attempts -1)  (not a hard coded 9, see bug above)
      9.times do
        post user_session_path(user: { email: user.email, password: 'incorrect' })
      end
    end
    it 'user should not be locked' do
      expect(user.reload.access_locked?).to be_falsey
    end
    it 'after 10, the user should be locked' do
      post user_session_path(user: { email: user.email, password: 'incorrect' })
      expect(user.reload.access_locked?).to be_truthy
    end
  end
end
