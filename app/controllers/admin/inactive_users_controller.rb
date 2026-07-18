###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin
  # Devise-arm inactive-user management. The auth-agnostic bulk lives in the shared
  # Admin::Concerns::InactiveUserManagementBehavior; this controller carries only the
  # Devise-coupled #reactivate (random password + reset-instructions email).
  #
  # This controller is namespaced to prevent route collision with Devise.
  class InactiveUsersController < ApplicationController
    include Admin::Concerns::InactiveUserManagementBehavior

    def reactivate
      @user = User.inactive.find(params[:id].to_i)
      pass = Devise.friendly_token(50)
      @user.update(
        active: true,
        last_activity_at: Time.current,
        expired_at: nil,
        password: pass,
        password_confirmation: pass,
      )

      # FIXME(#186770279): shouldn't send for oauth-linked accounts
      @user.send_reset_password_instructions
      redirect_to({ action: :index }, notice: "User #{@user.name} re-activated")
    end
  end
end
