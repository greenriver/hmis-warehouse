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
  # sign_in links this user to the 'test' connector at jwt_connector_user_id, which is deliberately
  # not the warehouse user id — the Admin API is addressed by the IdP's id.
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

  # Both actions run on current_user, so an unguarded route wouldn't expose another user's address —
  # it would run on nil. Asserting the raise rather than a redirect is what shows authenticate_user!
  # ran ahead of the action; the gate itself is covered in warehouse_jwt_wiring_spec.rb.
  describe 'with no forwarded token' do
    it 'refuses the read-only tab' do
      expect { get edit_account_email_path }.to raise_error(Idp::UnauthenticatedRequestError)
    end

    it 'refuses to start a change' do
      expect { post begin_change_account_email_path }.to raise_error(Idp::UnauthenticatedRequestError)
    end
  end

  describe 'when the IdP offers email self-service (Keycloak)' do
    # Every render reads the account back, so the baseline holds the address we already have.
    # Contexts exercising a change override it.
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

      # Both actions offered as deep-links were launched from this tab, so their return trips come
      # back to it rather than dropping the user on account details.
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

      # Reconciliation is no longer scoped to a return trip: Keycloak decides where it drops the user
      # after a confirmation link, and often that is not here. kc_action_status is read only by
      # #change_expected?, which gates the apology copy, so this is the adopt path for the return
      # trip too.
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

    describe 'POST begin_change' do
      # The client the action runs under is what decides where Keycloak returns the user from the
      # confirmation link it mails, so it has to be the one configured for this deployment.
      it 'runs the action under the configured account client, and returns here from the form' do
        # account_client_id is a per-realm config column now, not a request-time ENV read.
        Idp::ServiceConfig.find_by(connector_id: connector_id).update!(account_client_id: 'warehouse-account')

        post begin_change_account_email_path

        query = Rack::Utils.parse_query(URI(response.location).query)
        expect(query['client_id']).to eq('warehouse-account')
        expect(query['kc_action']).to eq('UPDATE_EMAIL')
        expect(query['redirect_uri']).to include('account_email')
      end

      # Starting a change is not a write path for the address itself — that stays the IdP's.
      it 'writes nothing about the address, here or at the IdP' do
        post begin_change_account_email_path

        expect(user.reload.email).to eq('before@example.com')
        expect(a_request(:put, target_url)).not_to have_been_made
      end
    end

    # The IdP is the only thing that knows a change is in flight — nothing here records that one was
    # started.
    describe 'while a change is in flight' do
      # Keycloak holds the unconfirmed address separately from the live one, so the tab can name the
      # inbox to check.
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

    # An address edited in the admin console lands unverified, so this tab raises on every visit by
    # that user until someone fixes it. Ours to notice, not theirs.
    describe 'an unverified address at the IdP' do
      before(:each) do
        allow(Sentry).to receive(:capture_exception_with_info)
        stub_request(:get, target_url).to_return(
          status: 200,
          body: remote_representation.merge(email: 'after@example.com', emailVerified: false).to_json,
        )
      end

      # The other half of this — the same unverified address *with* kc_action_status=success, where
      # the user gets the apology copy — is 'refuses an address the IdP has not verified, and warns'
      # under 'returning from the IdP action'.
      it 'tells a casual visitor nothing, and pages Sentry' do
        get edit_account_email_path

        expect(response).to have_http_status(:ok)
        expect(user.reload.email).to eq('before@example.com')
        expect(response.body).to include('before@example.com')
        expect(flash[:alert]).to be_blank
        expect(Sentry).to have_received(:capture_exception_with_info)
      end
    end

    # This is a page people refresh, and each refresh would otherwise be another Admin API call into
    # the same failure.
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

      # The adopt path itself is 'adopts a verified address on an ordinary visit' above — the status
      # doesn't reach it. What's left here is the behavior the status does decide.

      # any_instance because the controller resolves its own User from the token, so the spec's
      # `user` is a different instance.
      it 'syncs HUD users with the previous email when HMIS is enabled' do
        allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)
        expect_any_instance_of(User).to receive(:sync_to_hud_users).with(previous_email: 'before@example.com')

        get edit_account_email_path(kc_action_status: 'success')

        expect(user.reload.email).to eq('after@example.com')
      end

      # Adopting the address without the HUD rows would leave HMIS rows keyed on an email we no
      # longer hold, and nothing retries it. See the controller for why the transactions are nested.
      it 'unwinds the adopted address when the HUD sync fails' do
        allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)
        allow_any_instance_of(User).to receive(:sync_to_hud_users).and_raise(StandardError, 'HUD sync failed')

        expect { get edit_account_email_path(kc_action_status: 'success') }.
          to raise_error(StandardError, 'HUD sync failed')

        expect(user.reload.email).to eq('before@example.com')
      end

      # What the IdP still holds is what keeps us off the address, not the status — which is only a
      # hint about intent, and is why both of these take the same path.
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

    # An UPDATE_EMAIL action can't have produced this status, so there is nothing to reconcile and
    # nothing to apologise for.
    it 'ignores a return-trip status rather than warning about it' do
      get edit_account_email_path(kc_action_status: 'success')

      expect(response).to have_http_status(:ok)
      expect(user.reload.email).to eq('before@example.com')
      expect(a_request(:any, /#{Regexp.escape(api_url)}/)).not_to have_been_made
      expect(flash[:alert]).to be_blank
    end

    # Nothing renders the control here, but the route still accepts a POST, and there is no action
    # URL to send the browser to.
    it 'refuses to start a change' do
      expect { post begin_change_account_email_path }.to raise_error(RuntimeError, /not enabled/)
    end
  end
end
