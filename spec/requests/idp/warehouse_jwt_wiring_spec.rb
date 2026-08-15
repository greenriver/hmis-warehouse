###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

# Proves the warehouse request layer wires the JWT auth path when a Deployment boots with
# AUTH_METHOD=jwt, leaving the Devise path unchanged. The `if: AuthMethod.jwt?` examples lean on
# JwtAuthenticationHelper, which is included only when AuthMethod.jwt?.
RSpec.describe 'Warehouse JWT wiring', type: :request do
  describe 'authentication via a forwarded JWT', :jwt_only do
    let(:user) { create :user }

    before do
      # Keep this a focused wiring test: neutralize the post-auth setup gates so a fresh user
      # reaches the action, and resolve current_user deterministically from the mock token.
      allow(user).to receive(:training_required?).and_return(false)
      allow(user).to receive(:pending_compliance_requirements).and_return([])
      allow(User).to receive(:find_or_create_from_jwt).and_return(user)
    end

    # These exercise the JWT filter-chain *wiring*, not token validation: the resolution chain is
    # stubbed (find_or_create_from_jwt + JwtHelper.new via sign_in), so they prove the before-action
    # chain admits a resolved user and reaches the action. Token→user resolution correctness (valid?
    # false, find_or_create vs find_from_jwt, impersonation) lives in Idp::JwtCurrentUser's spec. The
    # deny side of the gate is the unauthenticated example below: it asserts a raise rather than
    # keepalive's own head(:unauthorized), which is what proves authenticate_user! actually guards it.
    it 'admits an authenticated JWT request through the filter chain and reports token expiry (GET → 200)' do
      sign_in(user)

      get session_keepalive_path

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body).to include('expiration_time', 'remaining_seconds')
      expect(body['remaining_seconds']).to be > 0
    end

    it 'serves session_keepalive over POST too (the inactivity-modal renew button POSTs)' do
      sign_in(user)

      post session_keepalive_path

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include('expiration_time', 'remaining_seconds')
    end

    # A redirect here would go to a proxy that still has a session and come straight back with the
    # same token.
    describe 'a forwarded token the app refuses' do
      # Stubbed reason rather than a real bad token: the JWT env keys aren't set in test, so real
      # validation can't run here. Which reason is which is Idp::JwtHelper's spec.
      let(:headers) { { 'HTTP_X_FORWARDED_ACCESS_TOKEN' => 'refused-token' } }

      before do
        refused = instance_double(
          Idp::JwtHelper,
          token?: true,
          valid?: false,
          invalid_reason: :malformed,
          invalid_reason_details: { reason: :malformed },
        )
        allow(Idp::JwtHelper).to receive(:new).and_wrap_original do |original_method, **kwargs|
          kwargs[:access_token] == 'refused-token' ? refused : original_method.call(**kwargs)
        end
      end

      it 'raises rather than reporting the request as signed out' do
        expect { get edit_account_path, headers: headers }.to raise_error(Idp::ForwardedTokenError, /malformed/)
      end

      # No per-action exceptions: authenticate_user! runs first everywhere, so every authenticated
      # route reports the misconfiguration the same way.
      it 'raises on the session routes too rather than converting it to a 401' do
        expect { get session_keepalive_path, headers: headers.merge('HTTP_ACCEPT' => 'application/json') }.
          to raise_error(Idp::ForwardedTokenError, /malformed/)
      end

      # Sign-out never reaches #destroy, so reset_session doesn't run and the IdP session stays
      # paired with a live Rails session rather than being silently orphaned.
      it 'raises on sign-out rather than resetting the session' do
        expect { delete destroy_user_session_path, headers: headers }.
          to raise_error(Idp::ForwardedTokenError, /malformed/)
      end
    end

    # The raise (not keepalive's own head(:unauthorized)) is the tell that authenticate_user! ran ahead
    # of the action — i.e. the shared JWT auth gate is wired onto this route. oauth2-proxy never passes
    # a tokenless request to a route that isn't a skip_auth_route, so reaching Rails is the defect.
    it 'raises on a request with no forwarded token rather than redirecting to sign-in' do
      expect { get session_keepalive_path }.to raise_error(Idp::UnauthenticatedRequestError)
    end

    # root is a skip_auth_route and skips authenticate_user!, so the deactivated wall has to come from
    # its own filter (reject_deactivated_user!) or it isn't there at all. This is the page the proxy
    # returns someone to after sign-in, so it's where a switched-off account first finds out.
    describe 'the public root page' do
      it 'walls off a deactivated token holder instead of serving the signed-out landing page' do
        sign_in(user)
        user.update!(active: false)

        get root_path

        expect(response).to have_http_status(:forbidden)
        expect(response.body).to include(Translation.translate('Your warehouse account has been deactivated'))
      end

      it 'still serves the landing page to a visitor with no token' do
        get root_path

        expect(response).to have_http_status(:ok)
      end

      # Deliberately not walled: on a realm shared with other apps, a valid token from someone who
      # was never a warehouse user is routine, and the public pages are public for them.
      it 'still serves the landing page to a token holder with no warehouse account' do
        sign_in(user)
        allow(User).to receive(:find_or_create_from_jwt).and_return(nil)

        get root_path

        expect(response).to have_http_status(:ok)
      end

      # The wall is an HTML page, so it only stands in front of HTML requests. Answering an image
      # request with it would replace the asset rather than tell anyone anything.
      it 'leaves a non-HTML request on a route that skips authentication to its own action' do
        sign_in(user)
        user.update!(active: false)

        get logo_path('logo.png')

        expect(response).not_to have_http_status(:forbidden)
      end
    end

    describe 'logout' do
      it 'resets the session, separate from the oauth2-proxy/IdP sign-out that follows the redirect' do
        sign_in(user)
        get session_keepalive_path
        expect(response).to have_http_status(:ok)
        # Asserted on a key the app writes (idp_sync_session_principal! stamps it during a normal
        # request): a session[...]= from the spec never reaches the next request, so it would read as
        # nil afterwards whether or not reset_session ran. reset_session in
        # Idp::SessionsController#destroy clears this, mirroring Devise's sign_out, so nothing
        # session-backed — impersonation included — can silently resume on the next sign-in.
        expect(session[Idp::JwtAuthentication::SESSION_PRINCIPAL_KEY]).to eq(user.id)

        delete destroy_user_session_path

        expect(response).to have_http_status(:redirect)
        expect(response.location).to include('/oauth2/sign_out')
        expect(session[Idp::JwtAuthentication::SESSION_PRINCIPAL_KEY]).to be_nil
      end

      describe 'ending the IdP session' do
        # The token's connector is 'test' (see JwtAuthenticationHelper), which ServiceFactory
        # resolves to a NullService, so a service has to be stubbed in to get past the predicate.
        let(:idp_service) do
          # profile_source and supports_email_self_service? are stubbed only to keep the per-session
          # profile sync inert; these examples are about sign-out.
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

        def start_session
          sign_in(user)
          get session_keepalive_path
          expect(response).to have_http_status(:ok)
        end

        it 'ends the token holder\'s IdP sessions, then resets and redirects' do
          start_session

          delete destroy_user_session_path

          expect(idp_service).to have_received(:logout_user_sessions).with(user_id: jwt_connector_user_id(user))
          expect(response).to redirect_to("/oauth2/sign_out?rd=#{CGI.escape(root_path)}")
        end

        describe 'from the terminal 403 pages (account_deactivated, no_warehouse_account)' do
          it 'signs out a user deactivated mid-session' do
            start_session
            user.update!(active: false)

            delete destroy_user_session_path

            expect(idp_service).to have_received(:logout_user_sessions).with(user_id: jwt_connector_user_id(user))
            expect(response).to redirect_to("/oauth2/sign_out?rd=#{CGI.escape(root_path)}")
          end

          it 'signs out a token holder with no warehouse account' do
            start_session
            allow(User).to receive(:find_or_create_from_jwt).and_return(nil)

            delete destroy_user_session_path

            expect(idp_service).to have_received(:logout_user_sessions).with(user_id: jwt_connector_user_id(user))
            expect(response).to redirect_to("/oauth2/sign_out?rd=#{CGI.escape(root_path)}")
          end

          # The link has to be on the page for any of the above to be reachable by a real user.
          it 'puts the sign-out control on errors/account_deactivated' do
            start_session
            user.update!(active: false)

            get edit_account_path

            expect(response).to have_http_status(:forbidden)
            expect(response.body).to include("href=\"#{destroy_user_session_path}\"", 'data-method="delete"')
          end

          it 'puts the sign-out control on errors/no_warehouse_account' do
            start_session
            allow(User).to receive(:find_or_create_from_jwt).and_return(nil)

            get edit_account_path

            expect(response).to have_http_status(:forbidden)
            expect(response.body).to include("href=\"#{destroy_user_session_path}\"", 'data-method="delete"')
          end
        end

        # Cross-site GET with no CSRF token, so it renders instead of acting — otherwise any page
        # could end every session the user holds in the realm. The 200 also rules out a hop to
        # /oauth2/sign_out, which would strip the token the button's DELETE needs.
        it 'renders a confirmation page on GET logout_talentlms without ending any session' do
          start_session

          get logout_talentlms_path

          expect(response).to have_http_status(:ok)
          expect(idp_service).not_to have_received(:logout_user_sessions)
          expect(session[Idp::JwtAuthentication::SESSION_PRINCIPAL_KEY]).to eq(user.id)
          expect(response.body).to include("href=\"#{destroy_user_session_path}\"", 'data-method="delete"')
        end

        # #destroy reads the id from the token rather than current_user precisely so impersonation
        # is safe: while impersonating, current_user is the impersonated user, so taking the id from
        # there would end that third party's sessions and leave the admin (the token holder) signed in.
        it 'ends the token holder\'s sessions, not the impersonated user\'s, while impersonating' do
          impersonated_user = create :user
          allow(impersonated_user).to receive(:training_required?).and_return(false)
          allow(impersonated_user).to receive(:pending_compliance_requirements).and_return([])
          allow(user).to receive(:can_edit_users?).and_return(true)
          allow(user).to receive(:can_impersonate_users?).and_return(true)
          allow(impersonated_user).to receive(:impersonateable_by?).with(user).and_return(true)
          # The impersonation path re-reads the true and impersonated users by id, and these two
          # objects carry the permission stubs above; without this they come back as plain rows and
          # the stored impersonation is discarded as unauthorized.
          allow(User).to receive(:find_by).and_call_original
          allow(User).to receive(:find_by).with(id: user.id).and_return(user)
          allow(User).to receive(:find_by).with(id: impersonated_user.id).and_return(impersonated_user)

          start_session
          # Impersonate through the app rather than assigning session[:impersonation] here: a spec's
          # session writes don't cross the request boundary, so poking it leaves the sign-out below
          # running with no impersonation at all, which passes just as well if the id comes off
          # current_user.
          post impersonate_admin_user_path(user, become_id: impersonated_user.id)
          expect(response).to have_http_status(:redirect)
          # X-app-user-id comes from current_user, so this is the app confirming the impersonation is
          # live on the session the sign-out reads.
          get session_keepalive_path
          expect(response.headers['X-app-user-id'].to_s).to eq(impersonated_user.id.to_s)

          delete destroy_user_session_path

          # The claim value, and exactly one call: rules out the impersonated user, and rules out
          # current_user.id / the token holder's warehouse id, which are a different string again.
          expect(idp_service).to have_received(:logout_user_sessions).
            with(user_id: jwt_connector_user_id(user)).once
          # The app wrote this entry, so reset_session dropping it is a real observation.
          expect(session[:impersonation]).to be_nil
        end

        # Fail closed: a failed IdP call aborts sign-out rather than reporting success it didn't
        # achieve. Deliberate, not an oversight.
        it 'aborts sign-out and leaves the session intact when the IdP call raises' do
          start_session
          allow(idp_service).to receive(:logout_user_sessions).
            and_raise(Idp::ServiceError.new('boom', idp_name: 'Keycloak', operation: :logout_user_sessions))
          expect(Sentry).to receive(:capture_exception_with_info)

          delete destroy_user_session_path

          expect(response).to have_http_status(:internal_server_error)
          # A rendered page in the app's layout, not bare text: the user arrives here on a full page
          # load and needs the retry link on it.
          expect(response).to render_template('errors/sign_out_failed')
          # The app writes this during start_session, so it's real session state — a value the spec
          # assigned directly wouldn't survive the request boundary. reset_session clears it.
          expect(session[Idp::JwtAuthentication::SESSION_PRINCIPAL_KEY]).to eq(user.id)
        end

        # Not knowing whether there's a session to end is not the same as knowing there isn't, so
        # this fails closed too — but with its own alert, since the fix is our config, not the IdP.
        it 'aborts sign-out when the connector\'s service can\'t be resolved' do
          start_session
          allow(Idp::ServiceFactory).to receive(:for_connector).with('test').and_raise(StandardError.new('bad config'))
          expect(Sentry).to receive(:capture_exception_with_info).
            with(anything, /Couldn't resolve the IDP service for connector test/)

          delete destroy_user_session_path

          expect(response).to have_http_status(:internal_server_error)
          expect(session[Idp::JwtAuthentication::SESSION_PRINCIPAL_KEY]).to eq(user.id)
        end

        # A hung IdP reaches the controller as the socket timeout the service didn't convert, so this
        # covers an exception that isn't an Idp::ServiceError taking the same fail-closed path.
        it 'aborts sign-out when the IdP call times out' do
          start_session
          allow(idp_service).to receive(:logout_user_sessions).and_raise(Net::ReadTimeout)
          allow(Sentry).to receive(:capture_exception_with_info)

          delete destroy_user_session_path

          expect(response).to have_http_status(:internal_server_error)
          expect(response).to render_template('errors/sign_out_failed')
          expect(session[Idp::JwtAuthentication::SESSION_PRINCIPAL_KEY]).to eq(user.id)
          # One report, not one per rescue on the way out.
          expect(Sentry).to have_received(:capture_exception_with_info).once
        end

        # A refused forwarded token must abort sign-out loudly rather than sign the user out locally
        # while the IdP session stays live. The refusal raises out of idp_token_holder, in the filter
        # that resolves current_user (#destroy itself skips authenticate_user!), so no session is
        # reset, no redirect issued, and no Keycloak teardown attempted.
        it 'refuses the sign-out when the forwarded token is refused' do
          start_session
          # sign_in memoizes one JwtHelper double per token, so this is the object the request reads.
          helper = Idp::JwtHelper.new(access_token: jwt_token)
          allow(helper).to receive(:invalid_reason).and_return(:bad_signature)
          allow(helper).to receive(:invalid_reason_details).and_return({ reason: :bad_signature })

          expect { delete destroy_user_session_path }.to raise_error(Idp::ForwardedTokenError, /bad_signature/)

          expect(idp_service).not_to have_received(:logout_user_sessions)
        end

        it 'signs out normally, without attempting a call, when the connector has no admin API' do
          allow(idp_service).to receive(:supports_session_logout?).and_return(false)
          start_session

          delete destroy_user_session_path

          expect(idp_service).not_to have_received(:logout_user_sessions)
          expect(response).to have_http_status(:redirect)
          expect(response.location).to include('/oauth2/sign_out')
        end

        it 'signs out normally, without attempting a call, for an unknown connector (NullService)' do
          allow(Idp::ServiceFactory).to receive(:for_connector).with('test').and_call_original
          start_session

          delete destroy_user_session_path

          expect(response).to have_http_status(:redirect)
          expect(response.location).to include('/oauth2/sign_out')
        end

        # #destroy skips authenticate_user!, so a token the provisioner can't resolve still reaches
        # the action and the blank-connector guard is what answers it. The HMIS arm walls the same
        # token off at authenticate_hmis_user! and answers 403 instead.
        it 'signs out normally, without attempting a call, when the token carries no connector claim' do
          start_session
          # No holder, rather than the outer block's pinned user: Idp::UserProvisioner needs the
          # connector claims to resolve one, so pinning it would hide that this token can't
          # authenticate at all.
          allow(User).to receive(:find_or_create_from_jwt).and_return(nil)
          # sign_in memoizes one JwtHelper double per token, so this hands back the same object the
          # request will read.
          allow(Idp::JwtHelper.new(access_token: jwt_token)).to receive(:connector_id).and_return(nil)

          delete destroy_user_session_path

          expect(idp_service).not_to have_received(:logout_user_sessions)
          # The guard short-circuits ahead of service resolution, so this can't pass by falling
          # through to a NullService whose capability predicate answers false.
          expect(Idp::ServiceFactory).not_to have_received(:for_connector).with(nil)
          expect(response).to have_http_status(:redirect)
          expect(response.location).to include('/oauth2/sign_out')
        end
      end
    end

    # The concern spec covers the branches. This covers the bit only the real stack shows: against
    # the live session store the session.id actually rotates, so two people's audit rows can't
    # share one.
    describe 'session boundary between IdP principals' do
      let(:other_user) { create :user }

      it 'starts a new Rails session when a different user authenticates on the same browser' do
        allow(other_user).to receive(:training_required?).and_return(false)
        allow(other_user).to receive(:pending_compliance_requirements).and_return([])
        # Resolve off the forwarded token rather than the flat stub in the outer before block, so
        # that signing in as someone else is what actually moves the principal.
        allow(User).to receive(:find_or_create_from_jwt) do |helper|
          helper.connector_user_id == jwt_connector_user_id(other_user) ? other_user : user
        end

        sign_in(user)
        get session_keepalive_path
        expect(response).to have_http_status(:ok)
        expect(session[Idp::JwtAuthentication::SESSION_PRINCIPAL_KEY]).to eq(user.id)
        first_session_id = session.id.to_s
        expect(first_session_id).to be_present

        # Someone else signs in on the same browser — the integration cookie jar carries the
        # session cookie forward.
        sign_in(other_user)

        get session_keepalive_path

        expect(response).to have_http_status(:ok)
        expect(session[Idp::JwtAuthentication::SESSION_PRINCIPAL_KEY]).to eq(other_user.id)
        expect(session.id.to_s).not_to eq(first_session_id)
      end
    end

    describe '#info_for_paper_trail' do
      # Use distinct current_user/true_user so the impersonation-audit behavior is actually
      # exercised: user_id must follow the true user (matching Devise's existing warden&.user&.id
      # semantics), not the impersonated user. With a single user for both, a
      # `user_id: current_user&.id` swap (the impersonation-audit bug) would pass unnoticed.
      it 'records the true user as user_id, not the impersonated user' do
        impersonated_user = create :user
        true_user = create :user
        controller = ApplicationController.new
        allow(controller).to receive(:current_user).and_return(impersonated_user)
        allow(controller).to receive(:true_user).and_return(true_user)
        allow(controller).to receive(:session).and_return(double(id: double(to_s: 'sess-1')))
        allow(controller).to receive(:request).and_return(double(uuid: 'req-1'))

        info = controller.send(:info_for_paper_trail)

        expect(info[:user_id]).to eq(true_user.id)
      end
    end
  end

  # Describe the connection class directly: a :channel group mixes in both Connection and Channel
  # TestCase behaviors, so `tests` resolves to the Channel variant (sets _channel_class). Naming the
  # class here makes it the described_class, which connection_class falls back to (else nil <= raises).
  describe ApplicationCable::Connection, :jwt_only, type: :channel do
    let(:user) { create :user }

    # Only the forwarded token resolves to the double; anything else builds a real Idp::JwtHelper,
    # which refuses it. That keeps the header the connection reads under test: read the wrong one (or
    # none) and the accepting examples below fail, rather than passing on a double that answers
    # valid? to whatever it was handed.
    def stub_forwarded_token(token, helper)
      allow(Idp::JwtHelper).to receive(:new).and_wrap_original do |original_method, **kwargs|
        kwargs[:access_token] == token ? helper : original_method.call(**kwargs)
      end
    end

    it 'accepts a connection with a valid forwarded token for an active user' do
      # Don't stub active? — the :user factory creates an active row, so the active? gate runs for real.
      jwt_helper = instance_double(Idp::JwtHelper, token?: true, valid?: true, invalid_reason: nil)
      stub_forwarded_token('forwarded-token', jwt_helper)
      allow(User).to receive(:find_from_jwt).with(jwt_helper).and_return(user)

      connect env: { 'HTTP_X_FORWARDED_ACCESS_TOKEN' => 'forwarded-token' }

      expect(connection.current_user).to eq(user)
    end

    it 'rejects a connection for a deactivated user even with a valid forwarded token' do
      inactive_user = create :user, active: false
      jwt_helper = instance_double(Idp::JwtHelper, token?: true, valid?: true, invalid_reason: nil)
      stub_forwarded_token('forwarded-token', jwt_helper)
      allow(User).to receive(:find_from_jwt).with(jwt_helper).and_return(inactive_user)

      expect { connect env: { 'HTTP_X_FORWARDED_ACCESS_TOKEN' => 'forwarded-token' } }.
        to have_rejected_connection
    end

    it 'rejects a connection with no forwarded token' do
      expect { connect }.to have_rejected_connection
    end

    # A plain rejection, not the raise the controllers do: a socket has no page to render, and every
    # page load during the same misconfiguration already reports it with full request context.
    it 'rejects a refused forwarded token without raising or reporting' do
      refused = instance_double(
        Idp::JwtHelper,
        token?: true,
        valid?: false,
        invalid_reason: :malformed,
        invalid_reason_details: { reason: :malformed },
      )
      stub_forwarded_token('refused-token', refused)
      expect(Sentry).not_to receive(:capture_message)

      expect { connect env: { 'HTTP_X_FORWARDED_ACCESS_TOKEN' => 'refused-token' } }.
        to have_rejected_connection
    end
  end

  describe "rack-attack's authenticated? helper", :jwt_only do
    it 'is true for a valid forwarded token' do
      allow(Idp::JwtHelper).to receive(:authenticated?).with('good-token').and_return(true)
      request = Rack::Attack::Request.new('QUERY_STRING' => '', 'HTTP_X_FORWARDED_ACCESS_TOKEN' => 'good-token')

      expect(request.authenticated?).to be(true)
    end

    it 'is false with no forwarded token' do
      request = Rack::Attack::Request.new('QUERY_STRING' => '', 'HTTP_X_FORWARDED_ACCESS_TOKEN' => nil)

      expect(request.authenticated?).to be(false)
    end
  end

  describe 'route surface' do
    it 'mounts /oauth/user-data only under Devise' do
      if AuthMethod.jwt?
        expect { Rails.application.routes.recognize_path('/oauth/user-data') }.
          to raise_error(ActionController::RoutingError)
      else
        expect(Rails.application.routes.recognize_path('/oauth/user-data')).
          to include(controller: 'oauth', action: 'user')
      end
    end

    it 'resolves the shared session route names to the right controller in each mode' do
      helpers = Rails.application.routes.url_helpers
      # Calling the helper proves it exists (the many *_path callers across the app depend on it);
      # recognize_path proves the name actually resolves to a live action — respond_to? alone would
      # pass even if the path 404'd.
      recognize = ->(path, method) { Rails.application.routes.recognize_path(path, method: method) }
      keepalive = recognize.call(helpers.session_keepalive_path, :post)
      logout = recognize.call(helpers.destroy_user_session_path, :delete)

      if AuthMethod.jwt?
        expect(keepalive).to include(controller: 'idp/sessions', action: 'keepalive')
        expect(logout).to include(controller: 'idp/sessions', action: 'destroy')
      else
        expect(keepalive).to include(controller: 'users/sessions', action: 'keepalive')
        expect(logout).to include(controller: 'users/sessions', action: 'destroy')
      end
    end
  end

  # Forced-logout machinery (a JWT token denylist) was never built — guard against it creeping back.
  describe 'forced-logout is absent' do
    it 'registers no check_token_denylist! before-action' do
      filters = ApplicationController._process_action_callbacks.map(&:filter)
      expect(filters).not_to include(:check_token_denylist!)
    end

    it 'does not route token_denylisted' do
      expect { Rails.application.routes.recognize_path('/token_denylisted') }.
        to raise_error(ActionController::RoutingError)
    end
  end
end
