###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class AccountPasswordsController < ApplicationController
  # before_action :authenticate_user!
  before_action :set_user

  def edit
    @user.set_initial_two_factor_secret!
    render 'accounts/edit'
  end

  def update
    if @user.update_with_password(account_params)
      flash[:notice] = 'Password was changed.'
      bypass_sign_in(@user)
      redirect_to edit_account_password_path
    else
      render action: :edit
    end
  end

  private def account_params
    params.require(:user).
      permit(
        :current_password,
        :password,
        :password_confirmation,
      )
  end

  private def set_user
    @user = current_user

    return redirect_to edit_account_path, alert: 'Change password not available.' unless @user.password_change_enabled?
  end
end
