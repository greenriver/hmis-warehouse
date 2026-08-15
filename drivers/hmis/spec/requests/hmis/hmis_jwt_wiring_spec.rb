###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'login_and_permissions'

# Proves the HMIS request layer wires the JWT auth path correctly when a Deployment boots with
# AUTH_METHOD=jwt. Mirrors spec/requests/idp/warehouse_jwt_wiring_spec.rb, but every auth-failure
# path returns JSON (the SPA contract) rather than an HTML redirect/render. The JWT examples lean on
# the JwtAuthenticationHelper sign_in, included only when AuthMethod.jwt?.
#
# find_or_create_from_jwt is deliberately NOT stubbed: sign_in provisions a real
# Idp::UserAuthenticationSource for the token's (connector_id, connector_user_id), so the real
# Idp::UserProvisioner resolves the holder off the token's own claims. Pinning the return value
# would make token→holder resolution unfalsifiable — resolving the wrong user, or ignoring the
# token entirely, would still pass. The one exception is the no-warehouse-account example, which
# stubs nil to force a branch that has no reachable fixture.
RSpec.describe 'HMIS JWT wiring', :jwt_only, type: :request do
  let(:ds) { create :hmis_primary_data_source }
  let(:headers) { { 'HOST' => ds.hmis } }

  describe 'authentication via a forwarded JWT' do
    it 'admits an authenticated JWT request through the filter chain (POST session_keepalive → 200)' do
      user = create(:hmis_user)
      sign_in(user)

      post hmis_session_keepalive_path, headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include('success' => true)
      # The holder resolved off the token's claims, not off whichever user the DB happened to
      # return: set_app_user_header reports current_hmis_user, so this is what makes the
      # unstubbed resolution above load-bearing.
      expect(response.headers['X-app-user-id'].to_s).to eq(user.id.to_s)
    end

    # GET rather than POST because SessionKeepalivesController aliases show to create, and the SPA
    # polls the GET. Not a CSRF assertion — config.action_controller.allow_forgery_protection is
    # false in test, and Rails never verifies the token on GET anyway.
    it 'admits the aliased GET session_keepalive as well as the POST' do
      user = create(:hmis_user)
      sign_in(user)

      get hmis_session_keepalive_path, headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include('success' => true)
      expect(response.headers['X-app-user-id'].to_s).to eq(user.id.to_s)
    end

    # Not a JSON 401: nothing authenticates its own callers here, so a tokenless request means the
    # proxy was bypassed, and a 401 would disguise that as an ordinary signed-out client.
    it 'raises on a request with no forwarded token rather than answering with a JSON 401' do
      expect { post hmis_session_keepalive_path, headers: headers }.
        to raise_error(Idp::UnauthenticatedRequestError)
    end

    # A good token whose holder has no warehouse account does get JSON, but 403 rather than 401:
    # signing in again can't produce an account.
    it 'returns a JSON 403 for a good token whose holder has no warehouse account' do
      # The one stubbed resolution in the file: Idp::UserProvisioner returns nil only when neither
      # the connector link nor the email matches, and sign_in provisions both, so there is no
      # fixture that reaches this branch for real.
      allow(User).to receive(:find_or_create_from_jwt).and_return(nil)
      sign_in(create(:hmis_user))

      post hmis_session_keepalive_path, headers: headers

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body).dig('error', 'type')).to eq('no_warehouse_account')
    end

    # The one auth failure the HMIS arm doesn't answer with JSON: the raise bypasses the
    # idp_handle_unauthenticated override on purpose. A 401 would tell the SPA to show a sign-in
    # screen for a problem no user can sign their way out of.
    it 'raises on a refused forwarded token instead of answering with a JSON 401' do
      refused = instance_double(
        Idp::JwtHelper,
        token?: true,
        valid?: false,
        invalid_reason: :invalid_audience,
        invalid_reason_details: { reason: :invalid_audience, expected_audiences: ['hmis'], actual_audience: 'other' },
      )
      allow(Idp::JwtHelper).to receive(:new).and_wrap_original do |original_method, **kwargs|
        kwargs[:access_token] == 'refused-token' ? refused : original_method.call(**kwargs)
      end

      expect { post hmis_session_keepalive_path, headers: headers.merge('HTTP_X_FORWARDED_ACCESS_TOKEN' => 'refused-token') }.
        to raise_error(Idp::ForwardedTokenError, /invalid_audience/)
    end

    it 'returns a JSON 403 for a locally-deactivated token holder (active = false)' do
      inactive = create(:hmis_user, active: false)
      sign_in(inactive)

      post hmis_session_keepalive_path, headers: headers

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body).dig('error', 'type')).to eq('account_deactivated')
    end
  end

  # The only route in this file that skips authenticate_hmis_user! (Hmis::UsersController:10), so
  # it is the one place where "no usable user" has to answer 200-with-no-user instead of raising or
  # rendering a JSON error. It's the SPA's bootstrap probe, and oauth2-proxy lists it as a
  # skip_auth_route, so it legitimately arrives with no token at all.
  describe 'GET /hmis/user.json' do
    it 'answers 200 with no user for a tokenless request, rather than raising as guarded routes do' do
      get hmis_user_path, headers: headers

      expect(response).to have_http_status(:ok)
      # Not merely "no id": the whole payload, so a future change that leaks another user's
      # values onto the signed-out bootstrap fails here.
      expect(JSON.parse(response.body)).to eq('impersonating' => false)
      expect(response.headers['X-app-user-id']).to be_blank
    end

    it 'answers 200 with an accountError for a deactivated holder' do
      sign_in(create(:hmis_user, active: false))

      get hmis_user_path, headers: headers

      expect(response).to have_http_status(:ok)
      # Match the whole payload with eq, not include: the terminal-state bootstrap must be exactly
      # these two keys. A regression that let current_hmis_user resolve would surface the holder's
      # full current_user_api_values here, and a partial matcher would still pass.
      expect(JSON.parse(response.body)).to eq('impersonating' => false, 'accountError' => 'account_deactivated')
    end

    it 'answers 200 with an accountError for a good token whose holder has no warehouse account' do
      # find_or_create_from_jwt returns nil only when neither the connector link nor the email
      # matches, and sign_in provisions both, so no fixture reaches this branch.
      allow(User).to receive(:find_or_create_from_jwt).and_return(nil)
      sign_in(create(:hmis_user))

      get hmis_user_path, headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq('impersonating' => false, 'accountError' => 'no_warehouse_account')
    end

    it 'has no accountError for an active signed-in user' do
      sign_in(create(:hmis_user))

      get hmis_user_path, headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).not_to have_key('accountError')
    end

    it 'reflects the actual primaryIdp connector value, not just its presence' do
      user = create(:hmis_user)
      sign_in(user)
      # sign_in (JwtAuthenticationHelper) provisions a real Authentication Source and sets
      # last_connector_id on the user; assert against that value rather than a hardcoded
      # literal, so this proves current_user_api_values surfaces the actual DB-backed
      # connector id (and would fail if it started always returning nil).
      expected_connector_id = user.reload.last_connector_id
      expect(expected_connector_id).to be_present

      get hmis_user_path, headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['primaryIdp']).to eq(expected_connector_id)
    end
  end

  # Mirrors the Devise impersonations_controller_spec setup, but drives the JWT arm:
  # impersonate_hmis_user / stop_impersonating_hmis_user back the Rails session via
  # Idp::ImpersonationManager, and the next request re-resolves (and re-validates) it.
  describe 'impersonation under JWT' do
    let(:user_group) { create(:hmis_user_group) }
    let(:admin_user) do
      user = create(:hmis_user, data_source: ds)
      create_access_control(user, ds, with_permission: [:can_impersonate_users], user_group: user_group)
      user
    end
    let(:target_user) { create(:hmis_user, data_source: ds).tap { |u| user_group.add(u) } }

    before do
      # The JWT holder is always the admin; impersonation targets are re-fetched from the session by
      # id, not from the token, so one holder exercises the whole round-trip.
      sign_in(admin_user)
    end

    it 'creates impersonation (session-backed) and reflects it in the same request' do
      post hmis_impersonations_path, params: { user_id: target_user.id }, headers: headers

      expect(response).to have_http_status(:ok)
      parsed = JSON.parse(response.body)
      expect(parsed['id']).to eq(target_user.id.to_s)
      expect(parsed['impersonating']).to eq(true)
      expect(controller.current_hmis_user).to eq(target_user)
    end

    it 'round-trips: a follow-up request honors the stored impersonation, then destroy clears it' do
      post hmis_impersonations_path, params: { user_id: target_user.id }, headers: headers
      expect(response).to have_http_status(:ok)

      # Fresh request: current_hmis_user is re-resolved from the session (per-request re-validation)
      # to the impersonated user, and the whodunnit follows it while true_user stays the admin.
      get hmis_user_path, headers: headers
      expect(response).to have_http_status(:ok)
      expect(controller.current_hmis_user).to eq(target_user)
      expect(controller.true_hmis_user).to eq(admin_user)
      expect(controller.send(:info_for_paper_trail)).to include(
        user_id: target_user.id,
        true_user_id: admin_user.id,
      )
      parsed = JSON.parse(response.body)
      expect(parsed).to have_key('primaryIdp')

      delete hmis_impersonations_path, headers: headers
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)['id']).to eq(admin_user.id.to_s)
      expect(controller.current_hmis_user).to eq(admin_user)
    end

    # The header comment above claims the next request re-VALIDATES the stored impersonation, but
    # the round-trip above only proves it re-resolves. Without this example, deleting the
    # idp_validate_impersonation_permissions guard (Idp::JwtAuthentication:218) leaves the whole
    # file green, and an admin whose can_impersonate_users? was revoked keeps reading a client's
    # record as that client for the life of the session.
    it 'drops the stored impersonation once the admin loses can_impersonate_users?' do
      post hmis_impersonations_path, params: { user_id: target_user.id }, headers: headers
      expect(response).to have_http_status(:ok)
      # Guard against a vacuous pass below: the impersonation really is in force first.
      get hmis_user_path, headers: headers
      expect(controller.current_hmis_user).to eq(target_user)

      # Revoke through the role that granted it, using the suite's own helper, rather than stubbing
      # can_impersonate_users? — so the real permission lookup is what changes its mind.
      remove_permissions(admin_user.access_controls.first, :can_impersonate_users)
      expect(Hmis::User.find(admin_user.id).can_impersonate_users?).to eq(false)

      get hmis_user_path, headers: headers

      expect(response).to have_http_status(:ok)
      expect(controller.current_hmis_user).to eq(admin_user)
      expect(controller.impersonating?).to eq(false)
      expect(JSON.parse(response.body)['id']).to eq(admin_user.id.to_s)
    end

    # idp_sync_session_principal! (Idp::JwtAuthentication:161) is what keeps a browser's session from
    # carrying across holders. Nothing else rotates the Rails session under JWT — there is no
    # sign-in event — so the session id is what PaperTrail and Hmis::ActivityLog would keep
    # attributing the new holder's actions to.
    #
    # The session ID is the assertion that makes this example load-bearing. Asserting only that the
    # impersonation didn't carry over does NOT work: the belt-and-braces true_user_id check at
    # Idp::JwtAuthentication:207-210 clears a foreign impersonation on its own, so deleting
    # `reset_session if stamped.present?` still yields the right current_hmis_user. Verified by
    # mutation — that version of this example stayed green.
    it 'rotates the session id when a different token holder arrives on the same cookie' do
      post hmis_impersonations_path, params: { user_id: target_user.id }, headers: headers
      expect(response).to have_http_status(:ok)
      admin_session_id = session.id.to_s
      expect(admin_session_id).to be_present

      # A second holder, same cookie jar: sign_in swaps the forwarded token but leaves the
      # @session_headers the helper has been carrying.
      other_user = create(:hmis_user, data_source: ds)
      sign_in(other_user)

      get hmis_user_path, headers: headers

      expect(response).to have_http_status(:ok)
      expect(session.id.to_s).not_to eq(admin_session_id)
      expect(session[Idp::JwtAuthentication::SESSION_PRINCIPAL_KEY]).to eq(other_user.id)
      # And the previous holder's impersonation is gone rather than inherited.
      expect(controller.current_hmis_user).to eq(other_user)
      expect(controller.impersonating?).to eq(false)
    end
  end

  describe 'logout' do
    it 'returns the oauth2-proxy sign-out URL as a JSON redirect_url, not an HTTP redirect' do
      user = create(:hmis_user)
      sign_in(user)

      delete destroy_hmis_user_session_path, headers: headers

      expect(response).to have_http_status(:ok)
      redirect_url = JSON.parse(response.body)['redirect_url']
      expect(redirect_url).to start_with('/oauth2/sign_out?rd=')
      expect(CGI.unescape(redirect_url.split('rd=').last)).to eq(root_path)
    end

    it 'clears session-stored impersonation, mirroring Devise sign_out, even though the JWT/oauth2-proxy credential is untouched' do
      user_group = create(:hmis_user_group)
      admin_user = create(:hmis_user, data_source: ds)
      create_access_control(admin_user, ds, with_permission: [:can_impersonate_users], user_group: user_group)
      target_user = create(:hmis_user, data_source: ds).tap { |u| user_group.add(u) }

      sign_in(admin_user)

      post hmis_impersonations_path, params: { user_id: target_user.id }, headers: headers
      expect(response).to have_http_status(:ok)

      delete destroy_hmis_user_session_path, headers: headers
      expect(response).to have_http_status(:ok)

      # Same JWT holder (admin_user) signs back in on what the server sees as the same
      # session/cookie jar; if logout hadn't cleared the impersonation, it would silently resume.
      get hmis_user_path, headers: headers
      expect(response).to have_http_status(:ok)
      expect(controller.current_hmis_user).to eq(admin_user)
      expect(controller.impersonating?).to eq(false)
    end

    # The session /oauth2/sign_out never reaches, since Dex doesn't propagate logout to Keycloak.
    # Mirrors spec/requests/idp/warehouse_jwt_wiring_spec.rb's set, JSON instead of HTML.
    describe 'ending the IdP session' do
      let(:user) { create(:hmis_user) }
      # The token's connector is 'test' (see JwtAuthenticationHelper), which resolves to a
      # NullService, so a service has to be stubbed in to get past the predicate.
      let(:idp_service) do
        # Idp::Support#idp_service builds a service for the user payload too, so this double answers
        # every for_connector('test') call an example makes, not only the sign-out's — hence
        # supports_email_self_service?, which Idp::Support#email_change_enabled? calls on each render,
        # and profile_source, which Idp::Support#profile_source calls once per session. Both are
        # stubbed only to keep the profile sync inert; these examples are about sign-out.
        instance_double(
          Idp::KeycloakService,
          supports_session_logout?: true,
          logout_user_sessions: true,
          supports_email_self_service?: false,
          profile_source: :admin_api,
        )
      end

      before do
        allow(Idp::ServiceFactory).to receive(:for_connector).and_call_original
        allow(Idp::ServiceFactory).to receive(:for_connector).with('test').and_return(idp_service)
      end

      def start_session(as: user)
        sign_in(as)
        get hmis_session_keepalive_path, headers: headers
        expect(response).to have_http_status(:ok)
      end

      def expect_signed_out_normally
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)['redirect_url']).to start_with('/oauth2/sign_out?rd=')
      end

      # The body is the whole contract with the SPA — throwMaybeHmisError reads the type, and no
      # redirect_url, since the SPA must not be handed a sign-out URL for a sign-out that didn't
      # happen.
      def expect_refused_sign_out
        expect(response).to have_http_status(:internal_server_error)
        expect(JSON.parse(response.body)).to eq('error' => { 'type' => 'sign_out_failed' })
        # Real session state, written by the app during start_session. reset_session clears it, and
        # fail-closed means reset_session never ran.
        expect(session[Idp::JwtAuthentication::SESSION_PRINCIPAL_KEY]).to eq(user.id)
      end

      it 'ends the token holder\'s IdP sessions, then resets and renders the sign-out URL' do
        start_session

        delete destroy_hmis_user_session_path, headers: headers

        expect(idp_service).to have_received(:logout_user_sessions).with(user_id: jwt_connector_user_id(user))
        expect_signed_out_normally
      end

      # Fail closed, deliberately: better than reporting a sign-out that didn't happen.
      it 'aborts sign-out and leaves the session intact when the IdP call raises' do
        start_session
        allow(idp_service).to receive(:logout_user_sessions).
          and_raise(Idp::ServiceError.new('boom', idp_name: 'Keycloak', operation: :logout_user_sessions))
        expect(Sentry).to receive(:capture_exception_with_info)

        delete destroy_hmis_user_session_path, headers: headers

        expect_refused_sign_out
      end

      # A hung IdP reaches the controller as the socket timeout the service didn't convert, so this
      # covers an exception that isn't an Idp::ServiceError taking the same fail-closed path.
      it 'aborts sign-out when the IdP call times out' do
        start_session
        allow(idp_service).to receive(:logout_user_sessions).and_raise(Net::ReadTimeout)
        allow(Sentry).to receive(:capture_exception_with_info)

        delete destroy_hmis_user_session_path, headers: headers

        expect_refused_sign_out
        # One report, not one per rescue on the way out.
        expect(Sentry).to have_received(:capture_exception_with_info).once
      end

      # Can't tell whether a session is live, so this fails closed too, with its own alert.
      it 'aborts sign-out when the connector\'s service can\'t be resolved' do
        start_session
        allow(Idp::ServiceFactory).to receive(:for_connector).with('test').and_raise(StandardError.new('bad config'))
        expect(Sentry).to receive(:capture_exception_with_info).
          with(anything, /Couldn't resolve the IDP service for connector test/)

        delete destroy_hmis_user_session_path, headers: headers

        expect_refused_sign_out
      end

      it 'signs out normally, without attempting a call, when the connector has no admin API' do
        allow(idp_service).to receive(:supports_session_logout?).and_return(false)
        start_session

        delete destroy_hmis_user_session_path, headers: headers

        expect(idp_service).not_to have_received(:logout_user_sessions)
        expect_signed_out_normally
      end

      # The real NullService, not the double. Its logout_user_sessions RAISES (Idp::NullService:53),
      # so this is what proves the supports_session_logout? guard runs before the call rather than
      # after: drop the guard and this goes red with a 500 sign_out_failed.
      it 'signs out normally, without attempting a call, for an unknown connector (NullService)' do
        allow(Idp::ServiceFactory).to receive(:for_connector).with('test').and_call_original
        start_session

        delete destroy_hmis_user_session_path, headers: headers

        # Not an exact count: the user payload consults the factory too (see idp_service above).
        expect(Idp::ServiceFactory).to have_received(:for_connector).with('test').at_least(:once)
        expect_signed_out_normally
      end

      it 'signs out a token with no connector claim via the blank-connector guard, without an IdP call' do
        start_session
        # sign_in memoizes one JwtHelper double per token, so this is the object the request reads.
        allow(Idp::JwtHelper.new(access_token: jwt_token)).to receive(:connector_id).and_return(nil)

        delete destroy_hmis_user_session_path, headers: headers

        # On the service, not on Idp::ServiceFactory: the user payload consults the factory too
        # (see idp_service above), so the factory cannot carry a never-consulted assertion.
        expect(idp_service).not_to have_received(:logout_user_sessions)
        expect_signed_out_normally
      end

      # A deactivated holder is locked out of HMIS, but a surviving Keycloak session signs the next
      # person at a shared machine straight back in.
      it 'ends the IdP session and signs out a deactivated token holder' do
        inactive = create(:hmis_user, active: false)
        sign_in(inactive)

        delete destroy_hmis_user_session_path, headers: headers

        expect(idp_service).to have_received(:logout_user_sessions).with(user_id: jwt_connector_user_id(inactive))
        expect_signed_out_normally
      end

      # The claims logout_user_sessions needs live on the token, not on the warehouse row, so a
      # holder without one still gets a full IdP sign-out.
      it 'ends the IdP session and signs out a good token whose holder has no warehouse account' do
        allow(User).to receive(:find_or_create_from_jwt).and_return(nil)
        holder = create(:hmis_user)
        sign_in(holder)

        delete destroy_hmis_user_session_path, headers: headers

        expect(idp_service).to have_received(:logout_user_sessions).with(user_id: jwt_connector_user_id(holder))
        expect_signed_out_normally
      end

      # The whole reason the id comes off the token: current_hmis_user is the impersonated user here,
      # so sourcing it there ends a third party's sessions and not the admin's.
      it 'ends the token holder\'s sessions, not the impersonated user\'s, while impersonating' do
        user_group = create(:hmis_user_group)
        admin_user = create(:hmis_user, data_source: ds)
        create_access_control(admin_user, ds, with_permission: [:can_impersonate_users], user_group: user_group)
        target_user = create(:hmis_user, data_source: ds).tap { |u| user_group.add(u) }

        start_session(as: admin_user)
        post hmis_impersonations_path, params: { user_id: target_user.id }, headers: headers
        expect(response).to have_http_status(:ok)

        delete destroy_hmis_user_session_path, headers: headers

        expect(response).to have_http_status(:ok)
        # The claim value, and exactly one call: rules out the impersonated user and both warehouse
        # ids, which are a different string again.
        expect(idp_service).to have_received(:logout_user_sessions).
          with(user_id: jwt_connector_user_id(admin_user)).once
      end

      # Why a forged DELETE reaches this action at all, and what it would cost: see
      # Hmis::Idp::SessionsController. allow_forgery_protection is false in the test environment
      # (config/environments/test.rb:55), so these examples turn it on — without that they pass
      # whether or not #destroy verifies the token.
      describe 'CSRF verification' do
        around do |example|
          ActionController::Base.allow_forgery_protection = true
          example.run
        ensure
          ActionController::Base.allow_forgery_protection = false
        end

        # Mirrors the SPA: fetchWithCsrf reads the CSRF-Token cookie set_csrf_cookie writes on every
        # Hmis::BaseController response and forwards it as X-CSRF-Token.
        def csrf_token_from_last_response
          response.cookies['CSRF-Token'].tap { |token| expect(token).to be_present }
        end

        it 'still signs out and still ends the IdP sessions when the request carries the token' do
          start_session
          token = csrf_token_from_last_response

          delete destroy_hmis_user_session_path, headers: headers.merge('X-CSRF-Token' => token)

          expect(idp_service).to have_received(:logout_user_sessions).with(user_id: jwt_connector_user_id(user))
          expect_signed_out_normally
        end

        it 'rejects a request with no token, without reaching the realm-wide logout' do
          start_session

          delete destroy_hmis_user_session_path, headers: headers

          expect(response).to have_http_status(:unauthorized)
          expect(JSON.parse(response.body)).to eq('error' => { 'type' => 'unverified_request' })
          expect(idp_service).not_to have_received(:logout_user_sessions)
        end

        # Guards the handle_unverified_request override on Hmis::Idp::SessionsController, through a
        # real retry rather than by reading `session` after the rejected request: that read reports
        # the request's inbound session, so it shows the pre-reset contents either way and stays
        # green with the override deleted.
        it 'leaves a rejected sign-out retryable with the token the browser already holds' do
          start_session
          token = csrf_token_from_last_response

          delete destroy_hmis_user_session_path, headers: headers
          expect(response).to have_http_status(:unauthorized)

          delete destroy_hmis_user_session_path, headers: headers.merge('X-CSRF-Token' => token)

          expect(idp_service).to have_received(:logout_user_sessions).with(user_id: jwt_connector_user_id(user)).once
          expect_signed_out_normally
        end

        # Same claim, the other piece of session state a reset would take: an admin mid-impersonation
        # would silently revert to acting as themselves, with the "Acting as" banner still on screen
        # from the last render.
        it 'leaves a rejected sign-out with the session-stored impersonation still in force' do
          user_group = create(:hmis_user_group)
          admin_user = create(:hmis_user, data_source: ds)
          create_access_control(admin_user, ds, with_permission: [:can_impersonate_users], user_group: user_group)
          target_user = create(:hmis_user, data_source: ds).tap { |u| user_group.add(u) }

          start_session(as: admin_user)
          post hmis_impersonations_path,
               params: { user_id: target_user.id },
               headers: headers.merge('X-CSRF-Token' => csrf_token_from_last_response)
          expect(response).to have_http_status(:ok)

          delete destroy_hmis_user_session_path, headers: headers
          expect(response).to have_http_status(:unauthorized)

          get hmis_user_path, headers: headers
          expect(controller.current_hmis_user).to eq(target_user)
          expect(controller.true_hmis_user).to eq(admin_user)
        end

        it 'still rejects a terminal-state holder with no CSRF token, without ending the IdP session' do
          sign_in(create(:hmis_user, active: false))

          delete destroy_hmis_user_session_path, headers: headers

          expect(response).to have_http_status(:unauthorized)
          expect(JSON.parse(response.body)).to eq('error' => { 'type' => 'unverified_request' })
          expect(idp_service).not_to have_received(:logout_user_sessions)
        end

        # A bare tokenless request would 401 on CSRF (checked ahead of the action) and never reach the
        # tokenless guard — passing even if the guard were gone. So sign in for a valid CSRF token, then
        # drop the JWT: CSRF passes, and the guard fires.
        it 'raises on a tokenless request that clears CSRF, rather than a quiet sign-out' do
          start_session
          token = csrf_token_from_last_response
          sign_out

          expect do
            delete destroy_hmis_user_session_path, headers: headers.merge('X-CSRF-Token' => token)
          end.to raise_error(Idp::UnauthenticatedRequestError)

          expect(idp_service).not_to have_received(:logout_user_sessions)
        end
      end
    end
  end

  describe '#info_for_paper_trail' do
    # Distinct current/true users so the whodunnit's audit-under-impersonation behavior is actually
    # exercised: user_id must follow the impersonated user, true_user_id the real one.
    it 'records the impersonated user as user_id and the real user as true_user_id' do
      impersonated_user = create :hmis_user
      true_user = create :hmis_user
      controller = Hmis::BaseController.new
      allow(controller).to receive(:current_hmis_user).and_return(impersonated_user)
      allow(controller).to receive(:true_hmis_user).and_return(true_user)
      allow(controller).to receive(:session).and_return(double(id: double(to_s: 'sess-1')))
      allow(controller).to receive(:request).and_return(double(uuid: 'req-1'))

      info = controller.send(:info_for_paper_trail)

      expect(info[:user_id]).to eq(impersonated_user.id)
      expect(info[:true_user_id]).to eq(true_user.id)
    end
  end
end
