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
# path returns JSON (the SPA contract) rather than an HTML redirect/render. The JWT examples run
# only under the AUTH_METHOD=jwt CI process (they lean on the JwtAuthenticationHelper sign_in,
# included only when AuthMethod.jwt?).
RSpec.describe 'HMIS JWT wiring', type: :request, if: AuthMethod.jwt? do
  let(:ds) { create :hmis_primary_data_source }
  let(:headers) { { 'HOST' => ds.hmis } }

  describe 'authentication via a forwarded JWT' do
    it 'admits an authenticated JWT request through the filter chain (POST session_keepalive → 200)' do
      user = create(:hmis_user)
      # idp_token_holder resolves the holder via find_or_create_from_jwt; pin it so resolution is
      # deterministic (token→user correctness is covered by Idp::JwtCurrentUser's own spec).
      allow(User).to receive(:find_or_create_from_jwt).and_return(User.find(user.id))
      sign_in(user)

      post hmis_session_keepalive_path, headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include('success' => true)
    end

    it 'admits the frontend\'s plain credentialed GET session_keepalive (no CSRF header)' do
      user = create(:hmis_user)
      allow(User).to receive(:find_or_create_from_jwt).and_return(User.find(user.id))
      sign_in(user)

      get hmis_session_keepalive_path, headers: headers

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include('success' => true)
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
      allow(User).to receive(:find_or_create_from_jwt).and_return(User.find(inactive.id))
      sign_in(inactive)

      post hmis_session_keepalive_path, headers: headers

      expect(response).to have_http_status(:forbidden)
      expect(JSON.parse(response.body).dig('error', 'type')).to eq('account_deactivated')
    end
  end

  describe 'GET /hmis/user.json' do
    it 'reflects the actual primaryIdp connector value, not just its presence' do
      user = create(:hmis_user)
      allow(User).to receive(:find_or_create_from_jwt).and_return(User.find(user.id))
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
      # id, not from the token (so a single pinned holder exercises the whole round-trip).
      allow(User).to receive(:find_or_create_from_jwt).and_return(User.find(admin_user.id))
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
  end

  describe 'logout' do
    it 'returns the oauth2-proxy sign-out URL as a JSON redirect_url, not an HTTP redirect' do
      user = create(:hmis_user)
      allow(User).to receive(:find_or_create_from_jwt).and_return(User.find(user.id))
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

      allow(User).to receive(:find_or_create_from_jwt).and_return(User.find(admin_user.id))
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
        instance_double(
          Idp::KeycloakService,
          supports_session_logout?: true,
          logout_user_sessions: true,
        )
      end

      before do
        allow(Idp::ServiceFactory).to receive(:for_connector).and_call_original
        allow(Idp::ServiceFactory).to receive(:for_connector).with('test').and_return(idp_service)
      end

      def start_session(as: user)
        allow(User).to receive(:find_or_create_from_jwt).and_return(User.find(as.id))
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

      it 'signs out normally, without attempting a call, for an unknown connector (NullService)' do
        allow(Idp::ServiceFactory).to receive(:for_connector).with('test').and_call_original
        start_session

        delete destroy_hmis_user_session_path, headers: headers

        expect(idp_service).not_to have_received(:logout_user_sessions)
        expect_signed_out_normally
      end

      it 'signs out normally, without attempting a call, when the token carries no connector claim' do
        start_session
        # sign_in memoizes one JwtHelper double per token, so this is the object the request reads.
        allow(Idp::JwtHelper.new(access_token: jwt_token)).to receive(:connector_id).and_return(nil)

        delete destroy_hmis_user_session_path, headers: headers

        expect(idp_service).not_to have_received(:logout_user_sessions)
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
