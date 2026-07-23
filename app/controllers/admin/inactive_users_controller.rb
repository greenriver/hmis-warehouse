###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin
  class InactiveUsersController < ApplicationController
    include Admin::Concerns::InactiveUserManagementBehavior

    private def reactivate_user!
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
    end
  end
end
