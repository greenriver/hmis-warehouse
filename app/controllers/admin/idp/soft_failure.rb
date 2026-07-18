###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin
  module Idp
    # Best-effort IdP-push policy for the JWT-arm admin controllers. The local `active` flag is
    # the authoritative access gate and commits first; the IdP push must not block or roll back
    # that local change. On failure we report to Sentry and surface a warning alongside the
    # success notice, rather than failing the request or hiding the error.
    module SoftFailure
      extend ActiveSupport::Concern

      # Returns the block's result: truthy when the IdP push actually landed, and falsy when it
      # either soft-failed (rescued below) or had nothing to push to (the idp_* method returns
      # false for an account with no IdP link). Callers with no authoritative local change
      # (e.g. expire_password) use this to avoid claiming a success that never happened; a falsy
      # result with no flash[:alert] set is the silent no-op for a never-IdP-managed account.
      private def with_idp_soft_failure(warning)
        yield
      rescue ::Idp::ServiceError => e
        Sentry.capture_exception_with_info(e, warning, { user_id: @user&.id })
        flash[:alert] = "#{warning}: #{e.message}"
        false
      end
    end
  end
end
