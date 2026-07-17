###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Provides user role information for Superset authentication via JWT.
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
