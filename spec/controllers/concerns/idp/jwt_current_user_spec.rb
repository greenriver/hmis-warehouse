###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Idp::JwtCurrentUser, type: :controller, if: AuthMethod.jwt? do
  controller(ActionController::Base) do
    include Idp::JwtCurrentUser

    def index
      render plain: current_user&.id.to_s
    end

    def auth
      authenticate_user!
      render plain: "authenticated:#{current_user&.id}" unless performed?
    end

    def who
      render plain: "#{true_user&.id}/#{impersonating?}"
    end

    def become
      impersonate_user(User.find(params[:id].to_i))
      render plain: "#{true_user&.id}/#{current_user&.id}"
    end

    def unbecome
      stop_impersonating_user
      render plain: "#{true_user&.id}/#{current_user&.id}"
    end
  end

  before do
    routes.draw do
      get 'index' => 'anonymous#index'
      get 'auth' => 'anonymous#auth'
      get 'who' => 'anonymous#who'
      get 'become' => 'anonymous#become'
      get 'unbecome' => 'anonymous#unbecome'
    end
    allow(controller).to receive(:idp_jwt_helper_for_request).and_return(jwt_helper)
  end

  let(:jwt_helper) do
    instance_double(
      Idp::JwtHelper,
      token?: true,
      valid?: true,
      invalid_reason: nil,
      invalid_reason_details: { reason: nil },
      connector_id: 'keycloak',
      expiration_time: 9_999_999_999,
    )
  end

  describe '#current_user' do
    it 'is nil when no token was forwarded' do
      allow(jwt_helper).to receive(:token?).and_return(false)
      allow(jwt_helper).to receive(:invalid_reason).and_return(:missing)

      get :index

      expect(response.body).to eq('')
    end
  end

  # None of these are a signed-out user, and redirecting them to a proxy that still holds a session
  # is what produces the bounce.
  describe 'a forwarded token we refuse' do
    Idp::JwtHelper::INVALID_REASONS.excluding(:missing).each do |reason|
      it "raises Idp::ForwardedTokenError for #{reason}" do
        allow(jwt_helper).to receive(:invalid_reason).and_return(reason)
        allow(jwt_helper).to receive(:invalid_reason_details).and_return({ reason: reason })

        expect { get :index }.to raise_error(Idp::ForwardedTokenError, /#{reason}/)
      end
    end

    it 'carries the expected and actual audience into the error message' do
      allow(jwt_helper).to receive(:invalid_reason).and_return(:invalid_audience)
      allow(jwt_helper).to receive(:invalid_reason_details).and_return(
        { reason: :invalid_audience, expected_audiences: ['warehouse'], actual_audience: 'something-else' },
      )

      expect { get :index }.to raise_error(Idp::ForwardedTokenError, /warehouse.*something-else/)
    end

    it 'does not raise for a missing token' do
      allow(jwt_helper).to receive(:token?).and_return(false)
      allow(jwt_helper).to receive(:invalid_reason).and_return(:missing)

      expect { get :index }.not_to raise_error
    end
  end

  describe '#idp_authenticated_user_from_jwt' do
    it 'resolves via find_or_create_from_jwt (the learning call), not find_from_jwt' do
      user = double('User', id: 7, active?: true)
      expect(User).to receive(:find_or_create_from_jwt).with(jwt_helper).and_return(user)
      expect(User).not_to receive(:find_from_jwt)

      get :index

      expect(response.body).to eq('7')
    end

    it 'sets the last_connector_id cookie from the token' do
      user = double('User', id: 7, active?: true)
      allow(User).to receive(:find_or_create_from_jwt).and_return(user)

      get :index

      expect(response.cookies['last_connector_id']).to eq('keycloak')
    end
  end

  # session[:scratch] stands in for ordinary session state. Unlike session[:impersonation] it has no
  # guard of its own, so its disappearance is what proves reset_session ran.
  describe 'session principal boundary (#idp_sync_session_principal!)' do
    let(:principal_key) { Idp::JwtAuthentication::SESSION_PRINCIPAL_KEY }
    let(:user) { double('User', id: 7, active?: true) }

    before { allow(User).to receive(:find_or_create_from_jwt).and_return(user) }

    it 'stamps the authenticated principal on the session' do
      get :index

      expect(session[principal_key]).to eq(7)
    end

    it 'discards session state left behind by a different principal' do
      session[principal_key] = 99
      session[:scratch] = 'previous user'
      session[:impersonation] = { true_user_id: 99, impersonated_user_id: 20 }

      get :index

      expect(response.body).to eq('7')
      expect(session[:scratch]).to be_nil
      expect(session[:impersonation]).to be_nil
      expect(session[principal_key]).to eq(7)
    end

    # oauth2-proxy refreshes the token mid-session, so this is the common case, not an edge one.
    it 'keeps the session when the same principal returns' do
      session[principal_key] = 7
      session[:scratch] = 'same user'

      get :index

      expect(session[:scratch]).to eq('same user')
      expect(session[principal_key]).to eq(7)
    end

    # An anonymous visitor's session, from a page that skips authenticate_user!.
    it 'stamps an unstamped session without discarding it' do
      session[:scratch] = 'no stamp yet'

      get :index

      expect(session[:scratch]).to eq('no stamp yet')
      expect(session[principal_key]).to eq(7)
    end

    # redis_store hands back an Integer today; this covers a future store that stringifies, where
    # the failure would be a reset on every request rather than a missed one.
    it 'treats a stringified stamp as a match' do
      session[principal_key] = '7'
      session[:scratch] = 'same user'

      get :index

      expect(session[:scratch]).to eq('same user')
    end

    # The 403 is terminal, so it must not render on the previous user's session.
    it 'discards a previous principal session even when the new principal is deactivated' do
      allow(User).to receive(:find_or_create_from_jwt).and_return(double('User', id: 9, active?: false))
      session[principal_key] = 99
      session[:scratch] = 'previous user'

      get :auth

      expect(response).to have_http_status(:forbidden)
      expect(session[:scratch]).to be_nil
      expect(session[principal_key]).to eq(9)
    end

    it 'leaves the session alone when no token resolves a user' do
      allow(User).to receive(:find_or_create_from_jwt).and_return(nil)
      session[principal_key] = 99
      session[:scratch] = 'previous user'

      get :index

      expect(session[:scratch]).to eq('previous user')
    end
  end

  describe '#authenticate_user!' do
    it 'sets current_user when a user is present' do
      # last_connector_id: the authenticated path also schedules the IdP read-back, which reads it.
      user = double('User', id: 5, active?: true, last_connector_id: nil)
      allow(User).to receive(:find_or_create_from_jwt).and_return(user)

      get :auth

      expect(response.body).to eq('authenticated:5')
    end

    # Kill-switch: a locally-deactivated user (active? == false) is denied even with a valid token.
    # We must NOT treat them as merely unauthenticated — a redirect to sign-in would loop off the
    # still-valid IdP token — so authenticate_user! routes to the terminal deactivated page instead.
    # This exercises the REAL idp_handle_deactivated (handler not stubbed): the 403 + deactivated
    # template prove it ran, and `not redirect` proves it did NOT fall through to the unauthenticated
    # sign-in redirect. render_template asserts the chosen template without needing render_views, so
    # the view's Translation.translate calls don't run here.
    it 'renders a terminal 403 deactivated page (not a sign-in redirect) for a deactivated user' do
      inactive_user = double('User', id: 9, active?: false)
      allow(User).to receive(:find_or_create_from_jwt).and_return(inactive_user)

      get :auth

      expect(response).to have_http_status(:forbidden)
      expect(response).to render_template('errors/account_deactivated')
    end

    it 'current_user is nil for a deactivated user' do
      inactive_user = double('User', id: 9, active?: false)
      allow(User).to receive(:find_or_create_from_jwt).and_return(inactive_user)

      get :index

      expect(response.body).to eq('')
    end

    # oauth2-proxy owns the sign-in redirect, and the only requests it passes through without a token
    # are skip_auth_routes, which all skip this filter. So a tokenless request arriving here means the
    # route surface and the proxy config disagree — ours to fix, not a user's to log in past.
    it 'raises when a route that requires authentication is reached with no token' do
      allow(jwt_helper).to receive(:token?).and_return(false)
      allow(jwt_helper).to receive(:invalid_reason).and_return(:missing)

      expect { get :auth }.to raise_error(Idp::UnauthenticatedRequestError, /\/auth/)
    end

    # The other way current_user comes back nil: Idp::UserProvisioner returns nil for a good token
    # with no matching user row when idp/auto_create_user is off, which is routine on a realm shared
    # with other apps. A real person who needs an account, so a terminal page — not a 500, and not a
    # redirect the proxy would bounce straight back with the same token.
    it 'renders a terminal 403 for a good token whose holder has no warehouse account' do
      allow(User).to receive(:find_or_create_from_jwt).and_return(nil)

      get :auth

      expect(response).to have_http_status(:forbidden)
      expect(response).to render_template('errors/no_warehouse_account')
    end
  end

  describe 'impersonation' do
    let(:true_user) do
      User.new.tap do |u|
        allow(u).to receive(:id).and_return(10)
        allow(u).to receive(:can_impersonate_users?).and_return(true)
        allow(u).to receive(:active?).and_return(true)
      end
    end
    let(:impersonated_user) do
      User.new.tap do |u|
        allow(u).to receive(:id).and_return(20)
        allow(u).to receive(:impersonateable_by?).with(true_user).and_return(true)
      end
    end

    before do
      allow(User).to receive(:find_or_create_from_jwt).and_return(true_user)
      allow(User).to receive(:find_by).with(id: 10).and_return(true_user)
      allow(User).to receive(:find_by).with(id: 20).and_return(impersonated_user)

      impersonation = double('Idp::ImpersonationManager')
      allow(impersonation).to receive(:get).and_return(
        true_user_id: 10,
        impersonated_user_id: 20,
      )
      allow(impersonation).to receive(:clear)
      allow(Idp::ImpersonationManager).to receive(:new).and_return(impersonation)
    end

    it 'current_user returns the impersonated user when permissions validate' do
      get :index

      expect(response.body).to eq('20')
    end

    it 'true_user returns the true user and impersonating? is true' do
      get :who

      expect(response.body).to eq('10/true')
    end

    it 'clears impersonation and returns the true user when the target is not impersonateable_by? the true_user' do
      allow(impersonated_user).to receive(:impersonateable_by?).with(true_user).and_return(false)

      get :index

      expect(response.body).to eq('10')
    end

    # Guards the can_impersonate_users? gate independently of impersonateable_by?: a true_user who
    # lost (or never had) impersonation privilege must fall back to themselves even though the target
    # would otherwise admit them. Without this, deleting the can_impersonate_users? check in
    # idp_validate_impersonation_permissions still passes the suite (impersonateable_by? alone admits).
    it 'clears impersonation and returns the true user when the true_user cannot impersonate' do
      allow(true_user).to receive(:can_impersonate_users?).and_return(false)

      get :index

      expect(response.body).to eq('10')
    end

    it 'ignores impersonation when the JWT principal is not the stored true_user' do
      # Leftover session: the token now logs in a different user (77) than the one who
      # started impersonating (10), so the impersonation should be ignored.
      other_principal = double('User', id: 77, active?: true)
      allow(User).to receive(:find_or_create_from_jwt).and_return(other_principal)

      get :index

      expect(response.body).to eq('77')
    end
  end

  # Uses the real Idp::ImpersonationManager (not the double from the describe block above) so the
  # session round-trip is exercised end to end, mirroring pretender's impersonate_user/
  # stop_impersonating_user.
  describe 'write-side (#impersonate_user / #stop_impersonating_user)' do
    let(:true_user) do
      User.new.tap do |u|
        allow(u).to receive(:id).and_return(10)
        allow(u).to receive(:active?).and_return(true)
        allow(u).to receive(:can_impersonate_users?).and_return(true)
      end
    end
    let(:impersonated_user) do
      User.new.tap do |u|
        allow(u).to receive(:id).and_return(20)
        allow(u).to receive(:impersonateable_by?).with(true_user).and_return(true)
      end
    end

    before do
      allow(User).to receive(:find_or_create_from_jwt).and_return(true_user)
      allow(User).to receive(:find).with(20).and_return(impersonated_user)
      allow(User).to receive(:find_by).with(id: 10).and_return(true_user)
      allow(User).to receive(:find_by).with(id: 20).and_return(impersonated_user)
    end

    it 'stores the impersonation in session and swaps current_user for the rest of the request' do
      get :become, params: { id: 20 }

      expect(response.body).to eq('10/20')
      expect(session[:impersonation]).to eq(true_user_id: 10, impersonated_user_id: 20)
    end

    it 'clears the session and restores current_user to the true user' do
      session[:impersonation] = { true_user_id: 10, impersonated_user_id: 20 }

      get :unbecome

      expect(response.body).to eq('10/10')
      expect(session[:impersonation]).to be_nil
    end
  end

  # When we ask the IdP; what the sync does with the answer is Idp::SyncUserFromIdpJob's spec.
  describe 'scheduling the IdP read-back (#idp_schedule_user_sync)' do
    let(:user) { double('User', id: 7, active?: true, last_connector_id: 'keycloak') }

    before do
      allow(User).to receive(:find_or_create_from_jwt).and_return(user)
      # NullStore holds nothing, so the connector pause would never engage.
      allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
    end

    it 'enqueues a sync once the request is authenticated' do
      expect { get :auth }.to have_enqueued_job(Idp::SyncUserFromIdpJob).with(user_id: 7)
    end

    it 'does not enqueue a second sync in the same session' do
      get :auth

      expect { get :auth }.not_to have_enqueued_job(Idp::SyncUserFromIdpJob)
    end

    it 'does not enqueue again however long the session lasts' do
      get :auth

      travel(3.days) do
        expect { get :auth }.not_to have_enqueued_job(Idp::SyncUserFromIdpJob)
      end
    end

    it 'enqueues again for a new session' do
      get :auth
      session.delete(Idp::JwtAuthentication::SESSION_SYNC_KEY)

      expect { get :auth }.to have_enqueued_job(Idp::SyncUserFromIdpJob).with(user_id: 7)
    end

    # idp_sync_session_principal! resets the session when the principal changes, which takes the
    # guard with it.
    it 'enqueues for a user who inherits a browser from someone else' do
      session[Idp::JwtAuthentication::SESSION_PRINCIPAL_KEY] = 99
      session[Idp::JwtAuthentication::SESSION_SYNC_KEY] = true

      expect { get :auth }.to have_enqueued_job(Idp::SyncUserFromIdpJob).with(user_id: 7)
    end

    # authenticate_user! only schedules once it has a user, so a request that resolves none never gets
    # here. Uses the no-account case rather than a missing token, which raises further up.
    it 'does not enqueue for a request that resolves no user' do
      allow(User).to receive(:find_or_create_from_jwt).and_return(nil)

      expect { get :auth }.not_to have_enqueued_job(Idp::SyncUserFromIdpJob)
    end

    it 'does not enqueue while the connector is paused' do
      Idp::SyncUserFromIdpJob.pause_connector!('keycloak')

      expect { get :auth }.not_to have_enqueued_job(Idp::SyncUserFromIdpJob)
    end

    # Otherwise every request in a session that started mid-outage retries until the pause lifts.
    it 'spends the session attempt even when the connector is paused' do
      Idp::SyncUserFromIdpJob.pause_connector!('keycloak')
      get :auth

      travel(Idp::SyncUserFromIdpJob::COOLDOWN_TTL + 1.minute) do
        expect { get :auth }.not_to have_enqueued_job(Idp::SyncUserFromIdpJob)
      end
    end

    it 'does not enqueue for a user with no connector on file' do
      allow(user).to receive(:last_connector_id).and_return(nil)

      expect { get :auth }.not_to have_enqueued_job(Idp::SyncUserFromIdpJob)
    end

    it 'syncs the token holder, not the account being impersonated' do
      impersonated_user = double('User', id: 20, active?: true, last_connector_id: 'keycloak')
      allow(user).to receive(:can_impersonate_users?).and_return(true)
      allow(impersonated_user).to receive(:impersonateable_by?).with(user).and_return(true)
      allow(User).to receive(:find_by).with(id: 7).and_return(user)
      allow(User).to receive(:find_by).with(id: 20).and_return(impersonated_user)
      session[:impersonation] = { true_user_id: 7, impersonated_user_id: 20 }

      expect { get :auth }.to have_enqueued_job(Idp::SyncUserFromIdpJob).with(user_id: 7)
    end
  end

  describe 'dropped methods (regression guard for the subtractions)' do
    it 'does not define forced-logout / provisioning / activity methods' do
      [:check_token_denylist!, :handle_denylisted_token, :ensure_authentication_source, :update_user_activity, :handle_inactive_user].each do |method_name|
        expect(controller.respond_to?(method_name, true)).to be(false), "expected #{method_name} not to be defined"
      end
    end
  end
end
