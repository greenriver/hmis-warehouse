###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Devise/Warden-path behavior for HMIS controllers; Hmis::Concerns::JwtHmisCurrentUser is the JWT
# arm's equivalent. Devise-only HMIS behavior belongs here, so the teardown is a single-file delete.
module Hmis::Concerns::DeviseHmisCurrentUser
  extend ActiveSupport::Concern

  included do
    private

    def session_duration_seconds
      Devise.timeout_in.in_seconds
    end

    # nil stub of the JWT arm's terminal_account_error, so Hmis::UsersController#show can call it
    # under both arms without a respond_to? check.
    def terminal_account_error
      nil
    end
  end
end
