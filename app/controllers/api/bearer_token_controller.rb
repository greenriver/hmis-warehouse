###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Api
  # Lean base for machine-to-machine JSON endpoints that authenticate with a bearer JWT
  # (`Authorization: Bearer <token>`), such as Superset's role lookup.
  #
  # It deliberately does NOT inherit from ApplicationController. That controller's filter chain is
  # built for an interactive browser session (require_training!, require_compliance_agreement!,
  # compose_activity/log_activity, 2FA, ...). Those filters key off current_user, and several of
  # them redirect_to a setup page when the user has outstanding onboarding. A server-to-server
  # caller carrying a live end-user token would then receive a 302 to an HTML page instead of the
  # JSON it asked for (and the redirect-follower would silently fall back to default behavior), and
  # every call would write an activity-log row. Riding a clean ActionController::Base — the same
  # choice Hmis::BaseController and SystemStatusController make — keeps this path to just the token
  # check below. See Api::SupersetController.
  class BearerTokenController < ActionController::Base
    include LogRagePayloadBehavior

    # Token-authenticated, session-less API: there is no form or cookie to forge against.
    skip_forgery_protection

    before_action :authenticate_via_jwt!

    private

    def authenticate_via_jwt!
      token = extract_bearer_token
      return head :unauthorized unless token.present?

      # Read-only lookup: this is a machine-to-machine identity query, not a login, so it must not
      # provision a user or learn an Authentication Source (see connection.rb#find_verified_user).
      @current_user = Idp::JwtHelper.active_user_from_token(token)
      unless @current_user
        Rails.logger.warn "#{self.class.name}: invalid/expired JWT token or inactive user"
        return head :unauthorized
      end
    end

    def extract_bearer_token
      auth_header = request.headers['Authorization']
      return nil unless auth_header.present?

      # Only accept the Bearer scheme; anything else (Basic, a bare token, a malformed header) is
      # not a token we should try to validate.
      match = auth_header.match(/\ABearer\s+(?<token>\S.*)\z/i)
      match && match[:token]
    end

    attr_reader :current_user

    # Lograge: attribute the request to the resolved user (parity with the other base controllers).
    def append_info_to_payload(payload)
      super
      payload[:user_id] = current_user&.id
    end
  end
end
