###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class AccountEmailsController < ApplicationController
  # before_action :authenticate_user!
  before_action :set_user

  def edit
    @user.set_initial_two_factor_secret!
    render 'accounts/edit'
  end

  def update
    changed_notes = []
    changed_notes << 'Account email was updated, check your inbox for a confirmation link.' if @user.email != account_params[:email]

    if @user.update_with_password(account_params)
      flash[:notice] = changed_notes.join(' ')
      bypass_sign_in(@user)
    else
      flash[:alert] = 'Unable to change email address'
    end
    redirect_to edit_account_email_path
  end

  private def account_params
    params.require(:user).
      permit(
        :email,
        :current_password,
      )
  end

  private def set_user
    @user = current_user

    return redirect_to edit_account_path, alert: 'Change email is not available.' unless @user.email_change_enabled?
  end
end
