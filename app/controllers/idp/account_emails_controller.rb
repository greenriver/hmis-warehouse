###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# JWT-arm email self-management. Email is a Warehouse profile field the IdP also owns, so a change
# commits locally and pushes to the IdP. There is no local password to confirm (no update_with_password)
# and no Devise confirmation mail. Reachable only when the connector accepts profile writes.
class Idp::AccountEmailsController < ApplicationController
  include Idp::SoftFailure

  before_action :set_user

  def edit
    render 'idp/accounts/edit'
  end

  def update
    email_before = @user.email

    if @user.update(account_params)
      if @user.email != email_before
        with_idp_soft_failure("Your email was saved, but we couldn't update it with your identity provider") do
          @user.idp_update_profile!(email: @user.email)
        end
        @user.sync_to_hud_users(previous_email: email_before) if HmisEnforcement.hmis_enabled?
        flash[:notice] = 'Account email was updated.'
      end
    else
      flash[:alert] = 'Unable to change email address'
    end
    redirect_to edit_account_email_path
  end

  private def account_params
    params.require(:user).permit(:email)
  end

  private def set_user
    @user = current_user

    return redirect_to edit_account_path, alert: 'Change email is not available.' unless @user.email_change_enabled?
  end
end
