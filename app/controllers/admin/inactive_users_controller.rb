###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Admin
  class InactiveUsersController < ApplicationController
    include Admin::Concerns::InactiveUserManagementBehavior

    # Devise arm: the account's old password is no good after deactivation, so scramble it and mail
    # a reset link.
    private def after_reactivate
      pass = Devise.friendly_token(50)
      @user.update!(password: pass, password_confirmation: pass)

      # FIXME(#186770279): shouldn't send for oauth-linked accounts
      @user.send_reset_password_instructions
    end
  end
end
