###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'webmock/rspec'

# JWT-arm email self-management, read-only.
RSpec.describe Idp::AccountEmailsController, :jwt_only, type: :request do
  let(:api_url) { 'http://keycloak.test:8080' }
  let(:realm) { 'openpath' }
  let(:connector_id) { 'test' } # matches JwtAuthenticationHelper#sign_in
  let(:token_url) { "#{api_url}/realms/#{realm}/protocol/openid-connect/token" }

  let!(:user) { create(:acl_user, first_name: 'Self', last_name: 'Serve', email: 'before@example.com') }
  # The Admin API addresses users by their IdP id, which jwt_connector_user_id supplies; sign_in
  # links this user to the 'test' connector under that id, which is not the warehouse user id.
  let(:target_url) { "#{api_url}/admin/realms/#{realm}/users/#{jwt_connector_user_id(user)}" }

  before(:each) do
    WebMock.disable_net_connect!
    stub_request(:post, token_url).to_return(
      status: 200,
      body: { access_token: 'test-token', expires_in: 300 }.to_json,
      headers: { 'Content-Type' => 'application/json' },
    )
    # The connector pause lives in the cache, which the test env nulls out.
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
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

  # The JWT arm raises rather than redirects when the request carries no authenticated user, so these
  # assert a raise. The auth gate itself is covered in warehouse_jwt_wiring_spec.rb.
  describe 'with no forwarded token' do
    it 'refuses the read-only tab' do
      expect { get edit_account_email_path }.to raise_error(Idp::UnauthenticatedRequestError)
    end

    it 'refuses to start a change' do
      expect { post begin_change_account_email_path }.to raise_error(Idp::UnauthenticatedRequestError)
    end
  end

  describe 'when the IdP offers email self-service (Keycloak)' do
    # Every render reads the account back; this baseline is the address we already hold.
    let(:remote_representation) { { id: jwt_connector_user_id(user), username: 'before@example.com', firstName: 'Self', lastName: 'Serve', email: 'before@example.com', emailVerified: true } }

    before(:each) do
      configure_keycloak!
      stub_request(:get, target_url).to_return(status: 200, body: remote_representation.to_json)
      sign_in user
    end

    describe 'GET edit' do
      it 'shows the current address read-only and offers a POST that starts the change' do
        get edit_account_email_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('before@example.com')
        expect(response.body).not_to include('name="user[email]"')
        expect(response.body).to include(begin_change_account_email_path)
        # The deep-link is built when that POST is handled, so the tab no longer carries it.
        expect(response.body).not_to match(/kc_action=UPDATE_EMAIL/)
      end

      it 'deep-links into the Keycloak password and 2FA actions' do
        get edit_account_email_path

        expect(response.body).to include("/realms/#{realm}/protocol/openid-connect/auth")
        expect(response.body).to match(/kc_action=UPDATE_PASSWORD/)
        expect(response.body).to match(/kc_action=CONFIGURE_TOTP/)
      end

      it 'sends both deep-linked actions back to this tab' do
        get edit_account_email_path

        links = response.body.scan(/\/realms\/#{realm}\/protocol\/openid-connect\/auth\?[^"]+/)
        expect(links.count).to eq(2)
        expect(links).to all(match(/redirect_uri=[^&]*account_email/))
      end

      it 'keeps the Login & Security tab in the nav' do
        get edit_account_path

        expect(response.body).to include(edit_account_email_path)
      end

      # Reconciliation runs on every render, not only on a return trip: Keycloak chooses where it
      # drops the user after a confirmation link, often not here. kc_action_status only gates the
      # apology copy (via #change_expected?), so it never decides whether we adopt.
      it 'adopts a verified address on an ordinary visit, with no return-trip status' do
        stub_request(:get, target_url).to_return(
          status: 200,
          body: remote_representation.merge(username: 'after@example.com', email: 'after@example.com').to_json,
        )

        get edit_account_email_path

        expect(user.reload.email).to eq('after@example.com')
        expect(response.body).to include('after@example.com')
        expect(flash[:notice]).to eq('Account email was updated.')
        # Adopting an address the IdP already confirmed is not a thing to mail anyone about.
        expect(ActionMailer::Base.deliveries).to be_empty
      end

      it 'says nothing on an ordinary visit when the address has not moved' do
        get edit_account_email_path

        expect(user.reload.email).to eq('before@example.com')
        expect(flash[:notice]).to be_blank
        expect(flash[:alert]).to be_blank
      end
    end

    # The controls edit the token holder (the admin), not the impersonated user, so the tab hides them.
    describe 'while impersonating another user' do
      let!(:impersonated_user) { create(:acl_user, first_name: 'Other', last_name: 'Person', email: 'other@example.com') }

      before(:each) do
        allow(impersonated_user).to receive(:training_required?).and_return(false)
        allow(impersonated_user).to receive(:pending_compliance_requirements).and_return([])
        allow(user).to receive(:can_edit_users?).and_return(true)
        allow(user).to receive(:can_impersonate_users?).and_return(true)
        allow(impersonated_user).to receive(:impersonateable_by?).with(user).and_return(true)
        # sign_in stubs find_from_jwt, but idp_token_holder resolves current_user via
        # find_or_create_from_jwt; without this the can_impersonate_users? stub above is silently ignored.
        allow(User).to receive(:find_or_create_from_jwt).and_return(user)
        # The impersonation path re-reads both users by id; without these stubs they come back as
        # plain rows missing the permissions above and the stored impersonation is discarded.
        allow(User).to receive(:find_by).and_call_original
        allow(User).to receive(:find_by).with(id: user.id).and_return(user)
        allow(User).to receive(:find_by).with(id: impersonated_user.id).and_return(impersonated_user)

        post impersonate_admin_user_path(user, become_id: impersonated_user.id)
      end

      it 'replaces the login & security controls with a message' do
        get edit_account_email_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to match(/can't change login and security settings for another user while impersonating/i)
        expect(response.body).not_to include(begin_change_account_email_path)
        expect(response.body).not_to match(/kc_action=UPDATE_PASSWORD/)
        expect(response.body).not_to match(/kc_action=CONFIGURE_TOTP/)
      end
    end

    describe 'POST begin_change' do
      # The client the action runs under is what decides where Keycloak returns the user from the
      # confirmation link it mails, so it has to be the one configured for this deployment.
      it 'runs the action under the configured account client, and returns here from the form' do
        # account_client_id is a per-realm config column, not a request-time ENV read.
        Idp::ServiceConfig.find_by(connector_id: connector_id).update!(account_client_id: 'warehouse-account')

        post begin_change_account_email_path

        query = Rack::Utils.parse_query(URI(response.location).query)
        expect(query['client_id']).to eq('warehouse-account')
        expect(query['kc_action']).to eq('UPDATE_EMAIL')
        expect(query['redirect_uri']).to include('account_email')
      end

      it 'writes nothing about the address, here or at the IdP' do
        post begin_change_account_email_path

        expect(user.reload.email).to eq('before@example.com')
        expect(a_request(:put, target_url)).not_to have_been_made
      end
    end

    describe 'while a change is in flight' do
      it 'names the address the IdP is waiting on' do
        stub_request(:get, target_url).to_return(
          status: 200,
          body: remote_representation.merge(attributes: { 'kc.email.pending' => ['after@example.com'] }).to_json,
        )

        get edit_account_email_path

        expect(response.body).to match(/waiting for you to confirm/i)
        expect(response.body).to include('after@example.com')
      end

      it 'says nothing about a pending address when the IdP holds none' do
        get edit_account_email_path

        expect(response.body).not_to match(/waiting for you to confirm/i)
      end
    end

    # An admin-console edit lands unverified, so this tab raises on every visit by that user until
    # someone fixes it — ours to notice (Sentry), not to alarm them about.
    describe 'an unverified address at the IdP' do
      before(:each) do
        allow(Sentry).to receive(:capture_exception_with_info)
        stub_request(:get, target_url).to_return(
          status: 200,
          body: remote_representation.merge(email: 'after@example.com', emailVerified: false).to_json,
        )
      end

      it 'tells a casual visitor nothing, and pages Sentry' do
        get edit_account_email_path

        expect(response).to have_http_status(:ok)
        expect(user.reload.email).to eq('before@example.com')
        expect(response.body).to include('before@example.com')
        expect(flash[:alert]).to be_blank
        expect(Sentry).to have_received(:capture_exception_with_info)
      end
    end

    describe 'while the connector is paused' do
      before(:each) do
        Idp::SyncUserFromIdpJob.pause_connector!(connector_id)
      end

      it 'renders the address we hold without reading the IdP back' do
        get edit_account_email_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('before@example.com')
        expect(a_request(:get, target_url)).not_to have_been_made
      end

      # The cooldown is about reaching the connector, not about what the user is entitled to do.
      it 'still offers the change' do
        get edit_account_email_path

        expect(response.body).to include(begin_change_account_email_path)
      end
    end

    describe 'returning from the IdP action' do
      let(:remote_representation) { { id: jwt_connector_user_id(user), username: 'after@example.com', firstName: 'Self', lastName: 'Serve', email: 'after@example.com', emailVerified: true } }

      # any_instance: the controller resolves its own User from the token, a different instance than
      # the spec's `user`.
      it 'syncs HUD users with the previous email when HMIS is enabled' do
        allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)
        expect_any_instance_of(User).to receive(:sync_to_hud_users).with(previous_email: 'before@example.com')

        get edit_account_email_path(kc_action_status: 'success')

        expect(user.reload.email).to eq('after@example.com')
      end

      # See Idp::AccountEmailsController for why the adopt and HUD sync share a nested transaction.
      it 'unwinds the adopted address when the HUD sync fails' do
        allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)
        allow_any_instance_of(User).to receive(:sync_to_hud_users).and_raise(StandardError, 'HUD sync failed')

        expect { get edit_account_email_path(kc_action_status: 'success') }.
          to raise_error(StandardError, 'HUD sync failed')

        expect(user.reload.email).to eq('before@example.com')
      end

      # The IdP still holding the old address is what keeps us off it — not kc_action_status, which
      # only hints at intent. So 'cancelled' and 'success' take the same path when it hasn't moved.
      {
        'cancelled' => 'the user cancelled',
        'success' => 'the action succeeded but the address did not move',
      }.each do |status, scenario|
        it "leaves the address alone and says nothing when #{scenario}" do
          stub_request(:get, target_url).to_return(
            status: 200,
            body: remote_representation.merge(username: 'before@example.com', email: 'before@example.com').to_json,
          )

          get edit_account_email_path(kc_action_status: status)

          expect(user.reload.email).to eq('before@example.com')
          expect(flash[:notice]).to be_blank
        end
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

      # A rejected write leaves Keycloak and users.email diverged until support intervenes — no
      # retry closes it — so it has to be loud rather than silent.
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

        # flash.now: the warning belongs to the request that renders it. A plain flash would persist
        # and warn the user again on their next visit to a tab where nothing went wrong.
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

    it 'refuses to start a change' do
      expect { post begin_change_account_email_path }.to raise_error(RuntimeError, /not enabled/)
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

    # Without email self-service there was no UPDATE_EMAIL action, so the return-trip status is
    # spurious — nothing to reconcile or apologise for.
    it 'ignores a return-trip status rather than warning about it' do
      get edit_account_email_path(kc_action_status: 'success')

      expect(response).to have_http_status(:ok)
      expect(user.reload.email).to eq('before@example.com')
      expect(a_request(:any, /#{Regexp.escape(api_url)}/)).not_to have_been_made
      expect(flash[:alert]).to be_blank
    end

    it 'refuses to start a change' do
      expect { post begin_change_account_email_path }.to raise_error(RuntimeError, /not enabled/)
    end
  end

  describe 'when the connector is authenticate-only (manage_users:false, app-1kz)' do
    let(:remote_representation) { { id: jwt_connector_user_id(user), username: 'before@example.com', firstName: 'Self', lastName: 'Serve', email: 'before@example.com', emailVerified: true } }

    before(:each) do
      create(
        :idp_service_config,
        :authenticate_only,
        connector_id: connector_id,
        provider: 'keycloak',
        api_url: api_url,
        keycloak_realm: realm,
      )
      sign_in user
    end

    describe 'GET edit' do
      it 'keeps the email change and credential deep-links live' do
        stub_request(:get, target_url).to_return(status: 200, body: remote_representation.to_json)

        get edit_account_email_path

        expect(response).to have_http_status(:ok)
        expect(response.body).to include(begin_change_account_email_path)
        expect(response.body).to match(/kc_action=UPDATE_PASSWORD/)
        expect(response.body).not_to match(/managed by your identity provider/i)
      end

      it 'makes no Admin API call: both IdP reads gate off the missing management capability' do
        stub_request(:get, target_url)

        get edit_account_email_path

        expect(response).to have_http_status(:ok)
        expect(a_request(:get, target_url)).not_to have_been_made
      end
    end

    describe 'POST begin_change' do
      it 'redirects into the IdP email-change action without any Admin API call' do
        post begin_change_account_email_path

        expect(response).to have_http_status(:redirect)
        expect(response.location).to match(/kc_action=UPDATE_EMAIL/)
        expect(a_request(:get, target_url)).not_to have_been_made
      end
    end
  end
end
