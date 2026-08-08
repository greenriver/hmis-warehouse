###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin
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

    # Devise arm: deactivation is purely local, no IdP to notify.
    private def after_deactivate
    end

    # Devise arm: identity fields have no separate remote store to push to.
    private def after_profile_update
    end

    # Devise arm: no fields are externally managed.
    private def externally_managed_param_keys
      []
    end
  end
end
