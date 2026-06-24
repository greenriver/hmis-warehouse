###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Idp
  # Serves the shared session route names (new_user_session / user_session / destroy_user_session /
  # session_keepalive / logout_talentlms) under AUTH_METHOD=jwt. Login and logout are owned by the
  # oauth2-proxy sidecar + the IdP, so these actions only bridge the legacy routes to proxy
  # redirects (sign-in/out) and report the forwarded token's expiry for the inactivity countdown
  # (keepalive). No Devise/Warden machinery is involved — current_user / authenticate_user! come
  # from Idp::CurrentUser, which ApplicationController includes under JWT.
  #
  # Only mounted by the AuthMethod.jwt? arm of config/routes.rb; the Devise arm routes the same
  # names to Users::SessionsController instead.
  class SessionsController < ApplicationController
    # sign-in is a redirect to the proxy, so these must not bounce off authenticate_user! first.
    skip_before_action :authenticate_user!, only: [:new, :create]

    # GET/POST users/sign_in — nothing in the JWT flow routes here (Idp::CurrentUser redirects
    # straight to the proxy on an unauthenticated request); this only catches stray hits on the
    # legacy login route and forwards them to the proxy.
    def new
      redirect_to oauth2_proxy_sign_in_path
    end
    alias_method :create, :new

    # DELETE users/sign_out (and GET logout_talentlms) — clear the proxy session and return to
    # root_url via the rd parameter.
    def destroy
      request.env['last_user'] = current_user

      redirect_to(
        "#{request.base_url}/oauth2/sign_out?rd=#{CGI.escape(root_url)}",
        allow_other_host: true,
      )
    end

    # GET/POST session_keepalive — report the forwarded token's expiry so the frontend countdown
    # can update (oauth2-proxy transparently refreshes the token on this request). The inactivity
    # modal's "I'm still here" button POSTs here, so both verbs are routed.
    def keepalive
      access_token = request.headers['HTTP_X_FORWARDED_ACCESS_TOKEN']
      return head(:unauthorized) unless access_token.present?

      jwt_helper = Idp::JwtHelper.new(access_token: access_token)
      return head(:unauthorized) unless jwt_helper.token? && jwt_helper.valid?

      expiration_time = jwt_helper.expiration_time
      return head(:ok) unless expiration_time

      remaining_seconds = [(expiration_time - Time.current).to_i, 0].max
      render(json: { expiration_time: expiration_time.to_i, remaining_seconds: remaining_seconds })
    end

    private

    # Reuses the same sign-in path builder Idp::CurrentUser#idp_handle_unauthenticated uses:
    # connector from the last_connector_id cookie, original URL captured for post-auth return.
    def oauth2_proxy_sign_in_path
      Idp::Oauth2ProxySignInPath.call(
        connector_id: cookies[:last_connector_id],
        redirect_to: Idp::PostAuthRedirect.new(request: request, cookies: cookies).capture,
      )
    end
  end
end
