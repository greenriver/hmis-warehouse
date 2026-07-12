###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis
  module Idp
    # Logout for AUTH_METHOD=jwt only; only mounted by the AuthMethod.jwt? arm of
    # drivers/hmis/config/routes.rb (the Devise arm keeps using Hmis::SessionsController, untouched).
    #
    # Mirrors ::Idp::SessionsController#destroy (the warehouse's JWT logout), but the SPA calls this
    # via fetch + response.json() rather than following a browser redirect, so the oauth2-proxy
    # sign-out URL comes back as a JSON field instead of an HTTP redirect.
    class SessionsController < Hmis::BaseController
      # The SPA's fetch-based logoutUser() call is separate from the shared authenticated API
      # client and doesn't attach an X-CSRF-Token header. Safe to skip here because this action has
      # no stateful side effect (no reset_session/sign_out) - it only computes a URL; the actual
      # sign-out happens at oauth2-proxy after the browser follows the returned redirect_url.
      skip_before_action :verify_authenticity_token, only: :destroy

      def destroy
        # Deliberately a relative path since oauth2-proxy is same-origin; an absolute URL built from
        # request.base_url could be spoofed via the Host header.
        render json: { redirect_url: "/oauth2/sign_out?rd=#{CGI.escape(root_path)}" }
      end
    end
  end
end
