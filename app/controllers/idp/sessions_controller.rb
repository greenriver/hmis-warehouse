###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Idp
  # Serves the shared session route names (new_user_session / user_session / destroy_user_session /
  # session_keepalive / logout_talentlms) under AUTH_METHOD=jwt. Login is owned by the oauth2-proxy
  # sidecar + the IdP, so these actions mostly bridge the legacy routes to proxy redirects and
  # report the forwarded token's expiry for the inactivity countdown (keepalive). #destroy is the
  # exception — it ends the IdP session itself, since the proxy hop doesn't reach Keycloak. No
  # Devise/Warden machinery is involved — current_user / authenticate_user! come from
  # Idp::JwtCurrentUser, which ApplicationController includes under JWT.
  #
  # Only mounted by the AuthMethod.jwt? arm of config/routes.rb; the Devise arm routes the same
  # names to Users::SessionsController instead.
  class SessionsController < ApplicationController
    # sign-in is a redirect to the proxy, so these must not bounce off authenticate_user! first.
    #
    # :destroy is here for the opposite reason. The terminal 403 pages
    # (errors/account_deactivated, errors/no_warehouse_account) render for someone who holds a good
    # token but has no usable current_user, so authenticate_user! sends them back to the same page
    # and they can never sign out — on a shared machine the next person inherits a live IdP session.
    # #destroy doesn't need current_user anyway: idp_end_token_holder_sessions reads the forwarded
    # token, which is also what lets it run before reset_session.
    #
    # So #destroy is the one action a token with no resolvable holder reaches, which is why the
    # blank-claim guard in idp_end_token_holder_sessions is live here and dead on the HMIS arm. A
    # token we outright refuse still doesn't get through: current_user is resolved by an earlier
    # filter in the chain, and idp_token_holder raises there.
    skip_before_action :authenticate_user!, only: [:new, :create, :destroy]
    # Same reason, one filter later: reject_deactivated_user! walls off the routes that skip
    # authenticate_user!, and signing out is the one thing a deactivated user still has to be able to
    # do — otherwise the link on errors/account_deactivated renders that page right back.
    skip_before_action :reject_deactivated_user!, only: [:new, :create, :destroy]

    # GET/POST users/sign_in — nothing in the JWT flow routes here (Idp::JwtCurrentUser redirects
    # straight to the proxy on an unauthenticated request); this only catches stray hits on the
    # legacy login route and forwards them to the proxy.
    def new
      redirect_to oauth2_proxy_sign_in_path
    end
    alias_method :create, :new

    # DELETE users/sign_out — end the IdP session, clear the Rails
    # session, then hand off to the proxy, which returns to root_path via the rd parameter.
    # Deliberately uses a relative path since oauth2-proxy is same-origin; an absolute URL built
    # from request.base_url could be spoofed via the Host header.
    def destroy
      # First: reads the token, not the session, and fails closed — a refusal means the SSO session is
      # still live, so nothing below runs. Cost accepted: while the IdP is unreachable nobody can sign
      # out. Don't make this best-effort. Hmis::Idp::SessionsController#destroy is the same sequence.
      idp_end_token_holder_sessions

      reset_session

      redirect_to("/oauth2/sign_out?rd=#{CGI.escape(root_path)}")
    rescue Idp::SessionLogoutRefused
      idp_handle_session_logout_failure
    end

    # GET logout_talentlms — TalentLMS redirects here when the user logs out of the LMS. Renders a
    # page whose button does the sign-out; must not sign out itself. It's a cross-site GET with no
    # CSRF token, so a forged one looks identical, and #destroy ends every session in the realm.
    #
    # Don't redirect to /oauth2/sign_out first: that drops the forwarded token the button's DELETE
    # authenticates with.
    def logout_talentlms
    end

    # GET/POST session_keepalive — report the forwarded token's expiry so the frontend countdown
    # can update (oauth2-proxy transparently refreshes the token on this request). The inactivity
    # modal's "I'm still here" button POSTs here, so both verbs are routed.
    def keepalive
      access_token = request.headers['HTTP_X_FORWARDED_ACCESS_TOKEN']
      return head(:unauthorized) unless access_token.present?

      jwt_helper = Idp::JwtHelper.new(access_token: access_token)
      # Defensive: a token we'd refuse raised in authenticate_user! and never reached this action.
      return head(:unauthorized) unless jwt_helper.valid?

      expiration_time = jwt_helper.expiration_time
      remaining_seconds = [(expiration_time - Time.current).to_i, 0].max
      render(json: { expiration_time: expiration_time.to_i, remaining_seconds: remaining_seconds })
    end

    private

    # Reuses the same sign-in path builder Idp::JwtCurrentUser#idp_handle_unauthenticated uses:
    # connector from the last_connector_id cookie, original URL captured for post-auth return.
    def oauth2_proxy_sign_in_path
      Idp::Oauth2ProxySignInPath.call(
        connector_id: cookies[:last_connector_id],
        redirect_to: Idp::PostAuthRedirect.new(request: request, cookies: cookies).capture,
      )
    end
  end
end
