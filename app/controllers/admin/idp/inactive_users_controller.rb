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

  def reactivate
    super
  rescue ::Idp::ServiceError => e
    Sentry.capture_exception_with_info(e, "Couldn't re-enable #{@user.name} in the identity provider")
    redirect_to({ action: :index }, alert: "Couldn't re-activate #{@user.name}: #{e.message}. Nothing was changed.")
  end

  # Push the IdP re-enable from inside the transaction holding the local reactivation, so the IdP
  # refusing the write rolls the local reactivation back too.
  #
  # The flash[:alert] set below survives super's redirect_to(notice:), which sets flash[:notice]
  # without clearing flash[:alert].
  private def after_reactivate
    return unless @user.idp_reactivate! == :identity_missing

    flash[:alert] = "#{@user.name} has no identity on file in the identity provider, so nothing " \
                    'was re-enabled there. Check that their account still exists.'
  end
end
