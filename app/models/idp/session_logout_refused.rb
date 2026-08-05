###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Idp
  # Couldn't end the token holder's IDP sessions, or couldn't tell whether to try. Either way a
  # session may still be live, so the sign-out that raised this tears nothing down: a user who
  # believes they signed out is worse, since on a shared machine the next person inherits the account.
  #
  # An exception rather than a false return so an unrescued raise still aborts the action — both
  # sign-out arms have to honor it. Already alerted to Sentry where it was raised; handlers shouldn't
  # report it again. Raised in Idp::JwtAuthentication#idp_end_token_holder_sessions, rescued into
  # idp_handle_session_logout_failure.
  class SessionLogoutRefused < StandardError
  end
end
