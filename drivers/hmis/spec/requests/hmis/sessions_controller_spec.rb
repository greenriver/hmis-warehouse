###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::SessionsController, type: :request do
  let(:user) { create :user }
  let(:user_2fa) { create :user_2fa }
  let(:email) { ActionMailer::Base.deliveries.last }
  let!(:ds1) { create :hmis_data_source }

  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end
  describe 'Successful login' do
    before(:each) do
      hmis_login(user)
    end

    it 'user failed_attempts should not increment' do
      expect(user.reload.failed_attempts).to eq 0
    end

    it 'updates session id' do
      expect(user.reload.hmis_unique_session_id).to be_present
    end

    it 'allows API access' do
      expect(api_query_response.status).to eq 200
    end

    it 'logs out' do
      delete destroy_hmis_user_session_path
      expect(response.status).to eq 204
      expect(api_query_response.status).to eq 401
    end
  end

  describe 'Un-successful login' do
    before(:each) do
      post hmis_user_session_path(hmis_user: { email: user.email, password: 'incorrect' })
    end

    it 'denys API access' do
      expect(api_query_response.status).to eq 401
    end

    # FIXME: we need to double the number of attempts because of a bug in devise 2FA that
    # hasn't been fixed yet https://github.com/tinfoil/devise-two-factor/pull/136
    # https://github.com/tinfoil/devise-two-factor/pull/130
    it 'user failed_attempts should increment' do
      expect(user.reload.failed_attempts).to eq 2
    end

    describe 'followed by a successful login' do
      before(:each) do
        hmis_login(user)
      end

      it 'user failed_attempts should return to 0' do
        expect(user.reload.failed_attempts).to eq 0
      end
    end
  end

  describe 'Un-successful login due to missing CSRF token' do
    before do
      ActionController::Base.allow_forgery_protection = true
    end
    after do
      ActionController::Base.allow_forgery_protection = false
    end
    it 'has correct response code' do
      hmis_login(user)
      expect(response.status).to eq 401
    end
  end

  describe 'Un-successful login due to inactive account' do
    before do
      user.update(active: false)
    end
    after do
      user.update(active: true)
    end
    it 'has correct response' do
      hmis_login(user)
      aggregate_failures 'checking response' do
        expect(response.status).to eq 401
        expect(response.body).to include 'inactive'
        expect(api_query_response.status).to eq 401
      end
    end
  end

  describe 'Account locked after 9 un-successful logins' do
    before(:each) do
      # Devise.maximum_attempts is twice what it should be (see Devise 2FA bug above)
      ((Devise.maximum_attempts / 2) - 1).times do
        post hmis_user_session_path(hmis_user: { email: user.email, password: 'incorrect' })
      end
    end
    it 'user should not be locked' do
      expect(user.reload.access_locked?).to be_falsey
    end
    it 'after 10, the user should be locked' do
      post hmis_user_session_path(hmis_user: { email: user.email, password: 'incorrect' })
      expect(user.reload.access_locked?).to be_truthy
    end
  end

  describe 'A locked account' do
    before(:each) { user.lock_access! }
    [
      [
        'correct password',
        ->(user, spec) { spec.hmis_login(user) },
      ],
      [
        'incorrect password',
        ->(user, spec) { spec.post spec.hmis_user_session_path(hmis_user: { email: user.email, password: 'incorrect' }) },
      ],
    ].each do |label, login_cb|
      it "fails authentication and indicates the account is locked for login with #{label}" do
        login_cb.call(user, self)
        expect(response.status).to eq(401)
        message = JSON.parse(response.body)
        expect(message.dig('error', 'type')).to eq('locked')
        expect(api_query_response.status).to eq 401
        expect(user.reload.access_locked?).to be_truthy
      end
    end
  end

  describe 'Login with 2FA enabled' do
    before(:each) do
      post hmis_user_session_path(hmis_user: { email: user_2fa.email, password: user_2fa.password })
    end

    it 'user failed_attempts should not increment' do
      expect(user_2fa.reload.failed_attempts).to eq 0
    end

    it 'user is expected to enter 2fa' do
      aggregate_failures 'checking response' do
        expect(response.status).to eq 403
        expect(response.body).to include 'mfa_required'
      end
    end

    it 'user logs in when correct 2fa entered' do
      post hmis_user_session_path(hmis_user: { otp_attempt: user_2fa.current_otp })
      aggregate_failures 'checking response' do
        expect(response.status).to eq 200
        expect(user_2fa.reload.failed_attempts).to eq 0
      end
    end

    it 'user does not log in when incorrect 2fa entered' do
      post hmis_user_session_path(hmis_user: { otp_attempt: '-1' })
      aggregate_failures 'checking response' do
        expect(response.status).to eq 403
        expect(response.body).to include 'invalid_code'
        expect(user_2fa.reload.failed_attempts).to eq 2 # double increment bug
      end
    end

    describe 'User does not remember 2FA device' do
      before(:each) do
        post hmis_user_session_path(hmis_user: { otp_attempt: user_2fa.current_otp, remember_device: nil })
        sign_out(user_2fa)
        post hmis_user_session_path(hmis_user: { email: user_2fa.email, password: user_2fa.password })
      end

      it 'user is expected to enter 2fa' do
        aggregate_failures 'checking response' do
          expect(response.status).to eq 403
          expect(response.body).to include 'mfa_required'
        end
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
      before(:all) do
        GrdaWarehouse::Config.first_or_create
        GrdaWarehouse::Config.update(bypass_2fa_duration: 30)
        GrdaWarehouse::Config.invalidate_cache
      end
      after(:all) do
        GrdaWarehouse::Config.delete_all
      end

      before(:each) do
        post hmis_user_session_path(hmis_user: { otp_attempt: user_2fa.current_otp, remember_device: true, device_name: 'Test Device' })
        delete destroy_hmis_user_session_path
        expect(response.status).to eq 204
        post hmis_user_session_path(hmis_user: { email: user_2fa.email, password: user_2fa.password })
      end

      it 'user failed_attempts should not increment' do
        aggregate_failures 'checking response' do
          expect(response.status).to eq 200
          expect(user_2fa.reload.failed_attempts).to eq 0
        end
      end

      it 'user does not have to enter 2fa on log in' do
        aggregate_failures 'checking response' do
          expect(response.status).to eq 200
          expect(response.body).to_not include 'mfa_required'
        end
      end

      it 'user has one memorized device' do
        aggregate_failures 'checking response' do
          expect(response.status).to eq 200
          expect(user_2fa.two_factors_memorized_devices.count).to eq 1
        end
      end

      it 'user has something in memorized device cookie' do
        aggregate_failures 'checking response' do
          expect(response.status).to eq 200
          device_uuid = user_2fa.two_factors_memorized_devices.first.uuid
          jar = ActionDispatch::Cookies::CookieJar.build(request, cookies.to_hash)
          expect(jar.encrypted[:memorized_device]).to eq device_uuid
        end
      end

      it 'user does not have to enter 2fa on log in before device expires' do
        travel_to Time.current + 30.days do
          delete destroy_hmis_user_session_path
          aggregate_failures 'checking response' do
            expect(response.status).to eq 204
            post hmis_user_session_path(hmis_user: { email: user_2fa.email, password: user_2fa.password })
            expect(response.status).to eq 200
          end
        end
      end

      it 'user has to reenter 2fa after device expires' do
        travel_to Time.current + 31.days do
          delete destroy_hmis_user_session_path
          aggregate_failures 'checking response' do
            expect(response.status).to eq 204
            post hmis_user_session_path(hmis_user: { email: user_2fa.email, password: user_2fa.password })
            expect(response.status).to eq 403
            expect(response.body).to include 'mfa_required'
          end
        end
      end
    end
  end

  def api_query_response
    query = <<~GRAPHQL
      query ClientSearch($input: ClientSearchInput!) {
        clientSearch(limit: 100, offset: 0, input: $input) {
          nodes {
            id
          }
        }
      }
    GRAPHQL
    response, = post_graphql(input: {}) { query }
    response
  end
end
