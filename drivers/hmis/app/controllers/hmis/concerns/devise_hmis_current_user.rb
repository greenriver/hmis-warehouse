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
  end
end
