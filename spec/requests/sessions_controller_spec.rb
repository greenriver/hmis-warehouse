require 'rails_helper'

RSpec.describe Users::SessionsController, type: :request do
  let(:user) { create :user }
  let(:user_2fa) { create :user_2fa }
  let(:email) { ActionMailer::Base.deliveries.last }

  describe 'Successful login' do
    before(:each) do
      post user_session_path(user: { email: user.email, password: user.password })
    end

    it 'user failed_attempts should not increment' do
      expect(user.reload.failed_attempts).to eq 0
    end
  end

  describe 'Un-successful login' do
    before(:each) do
      post user_session_path(user: { email: user.email, password: 'incorrect' })
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
      before(:each) do
        GrdaWarehouse::Config.first_or_create
        GrdaWarehouse::Config.update(bypass_2fa_duration: 30)
        GrdaWarehouse::Config.invalidate_cache
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
end
