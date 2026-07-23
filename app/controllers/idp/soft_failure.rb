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

    private def with_idp_soft_failure(warning)
      yield
    rescue ::Idp::ServiceError => e
      Sentry.capture_exception_with_info(e, warning)
      flash[:alert] = "#{warning}: #{e.message}"
      false
    end
  end
end
