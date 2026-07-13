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
      # Skipped defensively: the only stateful side effect here is reset_session (below), and a
      # forged cross-site request triggering that is a forced-logout nuisance at worst, not a
      # meaningful escalation - the actual credential (the oauth2-proxy/IdP session) is untouched
      # here regardless and only ends when the browser follows the returned redirect_url.
      skip_before_action :verify_authenticity_token, only: :destroy

      def destroy
        # wipes session so it doesn't outlive this login. Not a substitute for oauth2-proxy/IdP
        # sign-out the browser performs next via this redirect.
        reset_session

        # Deliberately a relative path since oauth2-proxy is same-origin; an absolute URL built from
        # request.base_url could be spoofed via the Host header.
        render json: { redirect_url: "/oauth2/sign_out?rd=#{CGI.escape(root_path)}" }
      end
    end
  end
end
