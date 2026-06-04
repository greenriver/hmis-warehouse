###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Provides user role information for Superset authentication via JWT.
# This endpoint is used by Superset when configured with oauth2-proxy/dex authentication.
# Unlike the Doorkeeper-based /oauth/user-data endpoint, this validates JWT tokens from dex.
module Api
  class SupersetController < ApplicationController
    skip_before_action :authenticate_user!
    before_action :authenticate_via_jwt!

    def user_roles
      payload = {
        id: current_user.id,
        first_name: current_user.first_name,
        last_name: current_user.last_name,
        email: current_user.email,
        superset_roles: current_user.superset_roles,
      }

      render(json: payload)
    end

    private

    def authenticate_via_jwt!
      token = extract_bearer_token
      return head :unauthorized unless token.present?

      jwt_helper = JwtHelper.new(access_token: token)
      unless jwt_helper.token? && jwt_helper.validate!
        Rails.logger.warn 'Superset API: Invalid or expired JWT token'
        return head :unauthorized
      end

      @current_user = User.find_from_jwt(jwt_helper)
      return if @current_user

      Rails.logger.warn "Superset API: User not found for email #{jwt_helper.payload_email}"
      return head :unauthorized
    end

    def extract_bearer_token
      auth_header = request.headers['Authorization']
      return nil unless auth_header.present?

      # Support both "Bearer token" and just "token" formats
      auth_header.sub(/^Bearer\s+/i, '')
    end

    attr_reader :current_user
  end
end
