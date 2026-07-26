###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Idp
  # A local change has already committed when the IdP write-back is attempted, so a failed push
  # must never roll the user's edit back: page Sentry, warn beside the save, and carry on.
  module SoftFailure
    extend ActiveSupport::Concern

    # `now:` picks the flash the caller's response actually reads: a redirecting action wants the
    # warning on the next request, an action that renders wants it on this one.
    private def with_idp_soft_failure(warning, now: false)
      yield
    rescue ::Idp::ServiceError => e
      Sentry.capture_exception_with_info(e, warning)
      (now ? flash.now : flash)[:alert] = "#{warning}: #{e.message}"
      false
    end
  end
end
