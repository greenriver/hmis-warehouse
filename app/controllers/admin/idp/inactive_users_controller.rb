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
  rescue ::Idp::ServiceError => e
    Sentry.capture_exception_with_info(e, "Couldn't re-enable #{@user.name} in the identity provider")
    redirect_to({ action: :index }, alert: "Couldn't re-activate #{@user.name}: #{e.message}. Nothing was changed.")
  end

  # Re-enable the account in the IdP from inside the transaction holding the local flip, so a
  # refused write takes the flip with it.
  private def after_reactivate
    @user.idp_reactivate!
  end
end
