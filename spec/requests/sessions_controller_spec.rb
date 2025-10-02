###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_contexts/post_login_hooks_context'
require 'support/shared_contexts/login_activity_context'

RSpec.describe Users::SessionsController, type: :request do
  let(:user) { create :user }
  let(:user_2fa) { create :user_2fa }
  let(:email) { ActionMailer::Base.deliveries.last }

  describe 'Successful login' do
    def do_login
      post user_session_path(user: { email: user.email, password: user.password })
    end

    context 'with standard behavior' do
      before(:each) do
        do_login
      end

      it 'user failed_attempts should not increment' do
        expect(user.reload.failed_attempts).to eq 0
      end
    end

    context 'with post-authentication hooks' do
      include_context 'with post-authentication hooks'
    end
  end

  describe 'Un-successful login' do
    before(:each) do
      post user_session_path(user: { email: user.email, password: 'incorrect' })
    end

    it 'user sees an error' do
      expect(response.body).to include 'Invalid Email or password'
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
      end

      it 'user failed_attempts should return to 0' do
        expect(user.reload.failed_attempts).to eq 0
      end
    end
  end

  context 'with login activity' do
    let(:scope) { 'user' }
    let(:activity_user) { user }
    def do_login
      post user_session_path(user: { email: user.email, password: user.password })
    end

    def do_failed_login
      post user_session_path(user: { email: user.email, password: 'incorrect' })
    end
    include_context 'with login activity tracking'
  end

  describe 'Account locked after 9 un-successful logins' do
    before(:each) do
      # Devise.maximum_attempts is twice what it should be (see Devise 2FA bug above)
      ((Devise.maximum_attempts / 2) - 1).times do
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

  describe 'Login with 2FA enabled' do
    before(:each) do
      post user_session_path(user: { email: user_2fa.email, password: user_2fa.password })
    end

    it 'user failed_attempts should not increment' do
      expect(user_2fa.reload.failed_attempts).to eq 0
    end

    it 'user is expected to enter 2fa' do
      expect(response).to render_template('devise/sessions/two_factor')
    end

    it 'user logs in when correct 2fa entered' do
      post user_session_path(user: { otp_attempt: user_2fa.current_otp })
      expect(user_2fa.reload.failed_attempts).to eq 0
    end

    it 'user does not log in when incorrect 2fa entered' do
      post user_session_path(user: { otp_attempt: '-1' })
      expect(user_2fa.reload.failed_attempts).to eq 2 # double increment bug
    end

    describe 'User does not remember 2FA device' do
      before(:each) do
        post user_session_path(user: { otp_attempt: user_2fa.current_otp, remember_device: nil })
        sign_out(user_2fa)
        post user_session_path(user: { email: user_2fa.email, password: user_2fa.password })
      end

      it 'user is expected to enter 2fa' do
        expect(response).to render_template('devise/sessions/two_factor')
      end

      it 'user has zero memorized device' do
        expect(user_2fa.two_factors_memorized_devices.count).to eq 0
      end

      it 'user has nothing in memorized device cookie' do
        jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
        expect(jar.encrypted[:memorized_device]).to eq nil
      end
    end

    describe 'User remembers 2FA device' do
      before(:all) do
        GrdaWarehouse::Config.first_or_create
        GrdaWarehouse::Config.update(bypass_2fa_duration: 30)
        GrdaWarehouse::Config.invalidate_cache
      end
      after(:all) do
        GrdaWarehouse::Config.delete_all
      end

      before(:each) do
        post user_session_path(user: { otp_attempt: user_2fa.current_otp, remember_device: true, device_name: 'Test Device' })
        sign_out(user_2fa)
        post user_session_path(user: { email: user_2fa.email, password: user_2fa.password })
      end

      it 'user failed_attempts should not increment' do
        expect(user_2fa.reload.failed_attempts).to eq 0
      end

      it 'user does not have to enter 2fa on log in' do
        expect(response).to_not render_template('devise/sessions/two_factor')
      end

      it 'user has one memorized device' do
        expect(user_2fa.two_factors_memorized_devices.count).to eq 1
      end

      it 'user has something in memorized device cookie' do
        device_uuid = user_2fa.two_factors_memorized_devices.first.uuid
        jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
        expect(jar.encrypted[:memorized_device]).to eq device_uuid
      end

      it 'user has to reenter 2fa after device expires' do
        travel_to Time.current + 31.days do
          sign_out(user_2fa)
          post user_session_path(user: { email: user_2fa.email, password: user_2fa.password })
          expect(response).to render_template('devise/sessions/two_factor')
        end
      end
    end
  end

  describe 'Logout redirect behavior' do
    before do
      sign_in user
    end

    context 'when Superset is available to the user' do
      it 'redirects to Superset logout with next pointing to the warehouse root' do
        allow(Superset).to receive(:available_to_user?).with(user).and_return(true)
        allow(Superset).to receive(:superset_base_url).and_return('https://superset.example.com')

        delete destroy_user_session_path

        expect(response).to redirect_to('https://superset.example.com/logout/?next=http%3A%2F%2Fwww.example.com%2F')
      end
    end

    context 'when Superset is not available to the user' do
      it 'redirects to the warehouse root' do
        allow(Superset).to receive(:available_to_user?).with(user).and_return(false)

        delete destroy_user_session_path

        expect(response).to redirect_to(root_url)
      end
    end
  end

  if ENV['OKTA_DOMAIN'].present?
    describe 'user with an okta/oauth identity' do
      it 'cannot login with a password' do
        identity = create(:oauth_identity, user: user)
        post user_session_path(user: { email: user.email, password: user.password })
        expect(response).to have_http_status(:success)
        expect(response.body).to include 'Invalid Email or password'
        identity.destroy!
      end
    end
  end
end
