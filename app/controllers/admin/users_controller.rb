###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin
  # Devise-arm admin user management. The auth-agnostic bulk lives in the shared
  # Admin::Concerns::UserManagementBehavior; this controller carries only the Devise-coupled
  # seams — the template-hook implementations and the Devise-only actions whose routes the JWT
  # arm omits (unlock, un_expire) or overrides (expire_password). At Devise sunset this class,
  # its routes, and the Devise-coupled partials are deleted; the JWT arm needs no unwinding.
  #
  # This controller is namespaced to prevent route collision with Devise.
  class UsersController < ApplicationController
    include Admin::Concerns::UserManagementBehavior

    def unlock
      @user.unlock_access!
      redirect_to({ action: :index }, notice: 'User unlocked')
    end

    def un_expire
      @user.update_last_activity!
      redirect_to({ action: :index }, notice: 'User re-activated')
    end

    def expire_password
      msg = if @user.force_password_reset!
        { notice: "User #{@user.email} has been logged out and will need to change their password on next login." }
      else
        { warn: "Unable to expire password for #{@user.email}, password expiration is disabled" }
      end
      redirect_to({ action: :index }, **msg)
    end

    # Devise arm: seed an OTP secret when rendering the edit form.
    private def initialize_two_factor_secret_for_edit
      @user.set_initial_two_factor_secret!
    end

    # Devise arm: clear 2FA when the admin unsets it in the form.
    private def disable_two_factor_if_requested
      @user.disable_2fa! if user_params[:otp_required_for_login] == 'false'
    end

    # Devise arm: suppress the :confirmable reconfirmation email on admin edits.
    private def skip_email_reconfirmation
      @user.skip_reconfirmation!
    end
  end
end
