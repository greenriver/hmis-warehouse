###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Admin::Idp::InactiveUsersController < ApplicationController
  include ::Admin::Concerns::InactiveUserManagementBehavior

  def _prefixes
    @_prefixes ||= [self.class.controller_path, 'admin/inactive_users'] + ApplicationController._prefixes
  end

  # The shared local flip and the IdP push share a transaction, so a refused push arrives here with
  # the local record untouched.
  def reactivate
    super

    # With no identity row the push is skipped rather than refused, so the local flip stands and the
    # user can sign in here again. The missing row still needs repair, so it is reported alongside
    # the success notice instead of silently. Read from the flag set during the push rather than by
    # re-asking the user: `super` has already redirected by this point, so anything that raises here
    # would hit the rescue below, redirect a second time, and turn a committed reactivation into a
    # DoubleRenderError reported as "Nothing was changed".
    return unless @idp_identity_missing

    flash[:alert] = "#{@user.name} has no identity on file in the identity provider, so nothing " \
                    'was re-enabled there. Check that their account still exists.'
  rescue ::Idp::ServiceError => e
    Sentry.capture_exception_with_info(e, "Couldn't re-enable #{@user.name} in the identity provider")
    redirect_to({ action: :index }, alert: "Couldn't re-activate #{@user.name}: #{e.message}. Nothing was changed.")
  end

  # Re-enable the account in the IdP from inside the transaction holding the local flip, so a
  # refused write takes the flip with it.
  #
  # #idp_reactivate! declines for two different reasons and reports neither, so the one worth telling
  # the admin about is recorded here, where the answer is still being computed inside the transaction
  # and a raise still reaches the rescue before anything has been rendered.
  private def after_reactivate
    @idp_identity_missing = @user.idp_identity_missing?
    @user.idp_reactivate!
  end
end
