###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Provides user role information for Superset authentication via JWT.
# This endpoint is used by Superset when configured with oauth2-proxy/dex authentication.
# Unlike the Doorkeeper-based /oauth/user-data endpoint, this validates JWT tokens from dex.
# Authentication (bearer token -> read-only user resolution) lives in Idp::JwtApiController;
# this M2M endpoint must not ride ApplicationController's interactive filter chain.
module Api
  class SupersetController < Idp::JwtApiController
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
  end
end
