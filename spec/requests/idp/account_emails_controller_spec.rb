###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

# JWT-arm email self-management, read-only. Requires the app to have booted under AUTH_METHOD=jwt.
RSpec.describe Idp::AccountEmailsController, type: :request, if: AuthMethod.jwt? do
  let(:api_url) { 'http://keycloak.test:8080' }
  let(:realm) { 'openpath' }
  let(:connector_id) { 'test' } # matches JwtAuthenticationHelper#sign_in
  let(:token_url) { "#{api_url}/realms/#{realm}/protocol/openid-connect/token" }

  let!(:user) { create(:acl_user, first_name: 'Self', last_name: 'Serve', email: 'before@example.com') }
  # sign_in links this user to the 'test' connector at connector_user_id == user.id.
  let(:target_url) { "#{api_url}/admin/realms/#{realm}/users/#{user.id}" }

  before(:each) do
    WebMock.disable_net_connect!
    stub_request(:post, token_url).to_return(
      status: 200,
      body: { access_token: 'test-token', expires_in: 300 }.to_json,
      headers: { 'Content-Type' => 'application/json' },
    )
    ActionMailer::Base.deliveries.clear
  end

  after(:each) do
    WebMock.reset!
    WebMock.allow_net_connect!
  end

  def configure_keycloak!
    create(
      :idp_service_config,
      connector_id: connector_id,
      provider: 'keycloak',
      api_url: api_url,
      keycloak_realm: realm,
    )
  end

  it 'exposes no update route — this arm never writes email locally' do
    expect { Rails.application.routes.recognize_path('/account_email', method: :patch) }.
      to raise_error(ActionController::RoutingError)
  end

  describe 'when the IdP offers email self-service (Keycloak)' do
    before(:each) do
      configure_keycloak!
      sign_in user
    end

    describe 'GET edit' do
      it 'shows the current address read-only and deep-links into the IdP UPDATE_EMAIL action' do
        get edit_account_email_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('before@example.com')
        expect(response.body).not_to include('name="user[email]"')
        expect(response.body).to include("#{api_url}/realms/#{realm}/protocol/openid-connect/auth")
        expect(response.body).to match(/kc_action=UPDATE_EMAIL/)
      end

      it 'deep-links into the Keycloak password and 2FA actions' do
        get edit_account_email_path

        expect(response.body).to include("/realms/#{realm}/protocol/openid-connect/auth")
        expect(response.body).to match(/kc_action=UPDATE_PASSWORD/)
        expect(response.body).to match(/kc_action=CONFIGURE_TOTP/)
      end

      # Every action offered on this tab was launched from it, so every return trip comes back to it
      # rather than dropping the user on account details.
      it 'sends all three actions back to this tab' do
        get edit_account_email_path

        links = response.body.scan(/\/realms\/#{realm}\/protocol\/openid-connect\/auth\?[^"]+/)
        expect(links.count).to eq(3)
        expect(links).to all(match(/redirect_uri=[^&]*account_email/))
      end

      it 'keeps the Login & Security tab in the nav' do
        get edit_account_path

        expect(response.body).to include(edit_account_email_path)
      end

      it 'does not touch the IdP on an ordinary visit' do
        get edit_account_email_path

        expect(a_request(:get, target_url)).not_to have_been_made
      end
    end

    describe 'returning from the IdP action' do
      let(:remote_representation) { { id: user.id.to_s, username: 'after@example.com', firstName: 'Self', lastName: 'Serve', email: 'after@example.com', emailVerified: true } }

      before(:each) do
        stub_request(:get, target_url).to_return(status: 200, body: remote_representation.to_json)
      end

      it 'adopts the verified address from the Admin API on kc_action_status=success' do
        get edit_account_email_path(kc_action_status: 'success')

        expect(user.reload.email).to eq('after@example.com')
        expect(response.body).to include('after@example.com')
        expect(flash[:notice]).to eq('Account email was updated.')
        expect(ActionMailer::Base.deliveries).to be_empty
      end

      it 'syncs HUD users with the previous email when HMIS is enabled' do
        allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)
        expect_any_instance_of(User).to receive(:sync_to_hud_users).with(previous_email: 'before@example.com')

        get edit_account_email_path(kc_action_status: 'success')
      end

      it 'leaves the address alone when the user cancelled' do
        get edit_account_email_path(kc_action_status: 'cancelled')

        expect(user.reload.email).to eq('before@example.com')
        expect(a_request(:get, target_url)).not_to have_been_made
        expect(flash[:notice]).to be_blank
      end

      it 'says nothing when the action succeeded but the address did not move' do
        stub_request(:get, target_url).to_return(
          status: 200,
          body: remote_representation.merge(username: 'before@example.com', email: 'before@example.com').to_json,
        )

        get edit_account_email_path(kc_action_status: 'success')

        expect(user.reload.email).to eq('before@example.com')
        expect(flash[:notice]).to be_blank
      end

      # A realm with Verify Email off applies the new address immediately, so the Admin API can hand
      # back an address nobody has proven. Adopting it would defeat the point of the deep-link.
      it 'refuses an address the IdP has not verified, and warns' do
        allow(Sentry).to receive(:capture_exception_with_info)
        stub_request(:get, target_url).to_return(
          status: 200,
          body: remote_representation.merge(emailVerified: false).to_json,
        )

        get edit_account_email_path(kc_action_status: 'success')

        expect(response).to have_http_status(:ok)
        expect(user.reload.email).to eq('before@example.com')
        expect(response.body).to include('before@example.com')
        expect(flash[:alert]).to match(/not verified after@example.com/)
        expect(Sentry).to have_received(:capture_exception_with_info)
      end

      # Nothing retries reconciliation, so a rejected write means Keycloak and users.email diverge
      # for good. It has to be loud rather than silent.
      it 'warns and pages Sentry when the new address is already taken in the Warehouse' do
        allow(Sentry).to receive(:capture_exception_with_info)
        create(:acl_user, first_name: 'Some', last_name: 'Body', email: 'after@example.com')

        get edit_account_email_path(kc_action_status: 'success')

        expect(response).to have_http_status(:ok)
        expect(user.reload.email).to eq('before@example.com')
        # The rejected value is dropped, so the read-only tab shows what we actually hold.
        expect(response.body).to include('before@example.com')
        expect(response.body).not_to include('after@example.com')
        expect(flash[:alert]).to match(/couldn't save the new address/)
        expect(Sentry).to have_received(:capture_exception_with_info)
      end

      context 'when the Admin API read fails' do
        before do
          stub_request(:get, target_url).to_return(status: 500, body: { error: 'boom' }.to_json)
          allow(Sentry).to receive(:capture_exception_with_info)
        end

        it 'still renders, keeps the old address, and pages Sentry' do
          get edit_account_email_path(kc_action_status: 'success')

          expect(response).to have_http_status(:ok)
          expect(user.reload.email).to eq('before@example.com')
          expect(Sentry).to have_received(:capture_exception_with_info)
          expect(flash[:alert]).to be_present
        end

        # The warning belongs to the request that renders it (flash.now); leaking it forward would
        # scold the user again on their next visit to a tab where nothing went wrong.
        it 'does not carry the warning into the next request' do
          get edit_account_email_path(kc_action_status: 'success')
          expect(flash[:alert]).to be_present

          get edit_account_email_path

          expect(flash[:alert]).to be_blank
        end
      end
    end
  end

  describe 'when the IdP service cannot be built (misconfigured Keycloak)' do
    before(:each) do
      sign_in user
      allow_any_instance_of(User).to receive(:idp_service).
        and_raise(Idp::ServiceError.new('Keycloak misconfigured, missing: realm'))
    end

    it 'renders the read-only tab with its explanatory copy instead of erroring' do
      get edit_account_email_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to match(/managed by your identity provider/i)
    end

    it 'does not attempt reconciliation on a return trip' do
      get edit_account_email_path(kc_action_status: 'success')

      expect(response).to have_http_status(:ok)
      expect(user.reload.email).to eq('before@example.com')
    end
  end

  describe 'when the IdP offers no email self-service (unconfigured => NullService)' do
    before(:each) { sign_in user }

    it 'still renders the tab, with the address and an explanation instead of a link' do
      get edit_account_email_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('before@example.com')
      expect(response.body).to match(/managed by your identity provider/i)
      expect(response.body).not_to match(/kc_action=UPDATE_EMAIL/)
      expect(response.body).not_to include('name="user[email]"')
    end

    it 'never calls the IdP' do
      get edit_account_email_path

      expect(a_request(:any, /#{Regexp.escape(api_url)}/)).not_to have_been_made
    end

    # An UPDATE_EMAIL action can't have produced this status, so there is nothing to reconcile and
    # nothing to apologise for.
    it 'ignores a return-trip status rather than warning about it' do
      get edit_account_email_path(kc_action_status: 'success')

      expect(response).to have_http_status(:ok)
      expect(user.reload.email).to eq('before@example.com')
      expect(a_request(:any, /#{Regexp.escape(api_url)}/)).not_to have_been_made
      expect(flash[:alert]).to be_blank
    end
  end
end
