require 'rails_helper'

RSpec.describe HmisApi::SessionsController, type: :request do
  let(:user) { create :user }
  let(:user_2fa) { create :user_2fa }
  let(:email) { ActionMailer::Base.deliveries.last }

  describe 'Successful login' do
    before(:each) do
      post hmis_api_user_session_path(hmis_api_user: { email: user.email, password: user.password })
    end

    it 'user failed_attempts should not increment' do
      expect(user.reload.failed_attempts).to eq 0
    end
  end

  describe 'Successful logout' do
    before(:each) do
      post hmis_api_user_session_path(hmis_api_user: { email: user.email, password: user.password })
    end

    it 'has correct response code' do
      expect(response.status).to eq 200
      delete destroy_hmis_api_user_session_path
      expect(response.status).to eq 204
    end
  end

  describe 'Un-successful login' do
    before(:each) do
      post hmis_api_user_session_path(hmis_api_user: { email: user.email, password: 'incorrect' })
    end

    # FIXME: we need to double the number of attempts because of a bug in devise 2FA that
    # hasn't been fixed yet https://github.com/tinfoil/devise-two-factor/pull/136
    # https://github.com/tinfoil/devise-two-factor/pull/130
    it 'user failed_attempts should increment' do
      expect(user.reload.failed_attempts).to eq 2
    end

    describe 'followed by a successful login' do
      before(:each) do
        post hmis_api_user_session_path(hmis_api_user: { email: user.email, password: user.password })
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
        post hmis_api_user_session_path(hmis_api_user: { email: user.email, password: 'incorrect' })
      end
    end
    it 'user should not be locked' do
      expect(user.reload.access_locked?).to be_falsey
    end
    it 'after 10, the user should be locked' do
      post hmis_api_user_session_path(hmis_api_user: { email: user.email, password: 'incorrect' })
      expect(user.reload.access_locked?).to be_truthy
    end
  end

  describe 'Login with 2FA enabled' do
    before(:each) do
      post hmis_api_user_session_path(hmis_api_user: { email: user_2fa.email, password: user_2fa.password })
    end

    it 'user failed_attempts should not increment' do
      expect(user_2fa.reload.failed_attempts).to eq 0
    end

    it 'user is expected to enter 2fa' do
      expect(response.status).to eq 403
      expect(response.body).to include 'mfa_required'
    end

    it 'user logs in when correct 2fa entered' do
      post hmis_api_user_session_path(hmis_api_user: { otp_attempt: user_2fa.current_otp })
      expect(response.status).to eq 200
      expect(user_2fa.reload.failed_attempts).to eq 0
    end

    it 'user does not log in when incorrect 2fa entered' do
      post hmis_api_user_session_path(hmis_api_user: { otp_attempt: '-1' })
      expect(response.status).to eq 403
      expect(response.body).to include 'invalid_code'
      expect(user_2fa.reload.failed_attempts).to eq 2 # double increment bug
    end

    describe 'User does not remember 2FA device' do
      before(:each) do
        post hmis_api_user_session_path(hmis_api_user: { otp_attempt: user_2fa.current_otp, remember_device: nil })
        sign_out(user_2fa)
        post hmis_api_user_session_path(hmis_api_user: { email: user_2fa.email, password: user_2fa.password })
      end

      it 'user is expected to enter 2fa' do
        expect(response.status).to eq 403
        expect(response.body).to include 'mfa_required'
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
      # HMIS frontend currently doesnt send remember_device or device_name
      before { skip('Disabled because of intermittent failues on CI') }

      before(:each) do
        GrdaWarehouse::Config.first_or_create
        GrdaWarehouse::Config.update(bypass_2fa_duration: 30)
        GrdaWarehouse::Config.invalidate_cache
        post hmis_api_user_session_path(hmis_api_user: { otp_attempt: user_2fa.current_otp, remember_device: true, device_name: 'Test Device' })
        delete destroy_hmis_api_user_session_path
        expect(response.status).to eq 204
        post hmis_api_user_session_path(hmis_api_user: { email: user_2fa.email, password: user_2fa.password })
      end

      it 'user failed_attempts should not increment' do
        expect(response.status).to eq 200
        expect(user_2fa.reload.failed_attempts).to eq 0
      end

      it 'user does not have to enter 2fa on log in' do
        expect(response.status).to eq 200
        expect(response.body).to_not include 'mfa_required'
      end

      it 'user has one memorized device' do
        expect(response.status).to eq 200
        expect(user_2fa.two_factors_memorized_devices.count).to eq 1
      end

      it 'user has something in memorized device cookie' do
        expect(response.status).to eq 200
        device_uuid = user_2fa.two_factors_memorized_devices.first.uuid
        jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
        expect(jar.encrypted[:memorized_device]).to eq device_uuid
      end

      it 'user does not have to enter 2fa on log in before device expires' do
        travel_to Time.current + 30.days do
          delete destroy_hmis_api_user_session_path
          expect(response.status).to eq 204
          post hmis_api_user_session_path(hmis_api_user: { email: user_2fa.email, password: user_2fa.password })
          expect(response.status).to eq 200
        end
      end

      it 'user has to reenter 2fa after device expires' do
        travel_to Time.current + 31.days do
          delete destroy_hmis_api_user_session_path
          expect(response.status).to eq 204
          post hmis_api_user_session_path(hmis_api_user: { email: user_2fa.email, password: user_2fa.password })
          expect(response.status).to eq 403
          expect(response.body).to include 'mfa_required'
        end
      end
    end
  end
end
