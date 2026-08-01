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

  # A refused push arrives here with the local record untouched.
  def reactivate
    super
  rescue ::Idp::ServiceError => e
    Sentry.capture_exception_with_info(e, "Couldn't re-enable #{@user.name} in the identity provider")
    redirect_to({ action: :index }, alert: "Couldn't re-activate #{@user.name}: #{e.message}. Nothing was changed.")
  end

  # Re-enable the account in the IdP from inside the transaction holding the local reactivation, so
  # a refused write rolls that back too.
  #
  # With no identity row the push is skipped rather than refused, so the local reactivation stands
  # and the user can sign in here again. The missing row still needs repair, so it is warned about
  # rather than passed over silently. The warning belongs here and not after `super` returns, which
  # is past the redirect: a raise here still reaches the rescue above with nothing rendered yet. The
  # alert survives `super`'s redirect_to, which sets :notice without clearing the flash.
  private def after_reactivate
    return unless @user.idp_reactivate! == :identity_missing

    flash[:alert] = "#{@user.name} has no identity on file in the identity provider, so nothing " \
                    'was re-enabled there. Check that their account still exists.'
  end
end
