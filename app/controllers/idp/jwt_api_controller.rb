###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Idp
  # Base for API endpoints that authenticate with an IdP-issued bearer JWT
  #
  # It deliberately does NOT inherit from ApplicationController to avoid bad interactions with
  # request hooks require_training, compliance_agreement, etc.
  class JwtApiController < ActionController::Base
    include LogRagePayloadBehavior

    # Token-authenticated, session-less API
    skip_forgery_protection

    before_action :authenticate_via_jwt!

    private

    def authenticate_via_jwt!
      token = extract_bearer_token
      return head :unauthorized unless token.present?

      # Read-only lookup: this is a machine-to-machine query; does not provision users
      @current_user = Idp::JwtHelper.active_user_from_token(token)
      return if @current_user

      Rails.logger.warn "#{self.class.name}: invalid/expired JWT token or inactive user"
      return head :unauthorized
    end

    def extract_bearer_token
      auth_header = request.headers['Authorization']
      return nil unless auth_header.present?

      # Only accept the Bearer scheme; reject all else
      match = auth_header.match(/\ABearer\s+(?<token>\S.*)\z/i)
      match && match[:token]
    end

    attr_reader :current_user

    # Lograge: parity with the other base controllers
    def append_info_to_payload(payload)
      super
      payload[:user_id] = current_user&.id
    end
  end
end
