###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Handles the captive portal for users with denylisted tokens.
#
# When an admin force-logs out a user, their JWT token is added to a denylist.
# The next request with that token redirects here, showing a message that
# the session has been terminated and providing a logout link.
class TokenDenylistedController < ApplicationController
  skip_before_action :check_token_denylist!, only: [:show]
  skip_before_action :verify_authenticity_token, only: [:show]

  # Display the token denylisted (forced logout) page.
  #
  # This is a captive portal shown to users whose sessions have been terminated
  # by an admin. It provides a clear message and a link to the OAuth2-proxy
  # logout endpoint.
  def show
    # Extract JWT payload for debugging (development only)
    return unless Rails.env.development?

    @jwt_payload = jwt_helper_for_request&.payload&.first
  end
end
