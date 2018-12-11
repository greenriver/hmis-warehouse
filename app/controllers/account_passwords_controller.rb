class AccountPasswordsController < ApplicationController
  #before_action :authenticate_user!
  before_action :set_user

  def edit
    render 'accounts/edit'
  end

  def update
    if @user.update_with_password(account_params)
      flash[:notice] = "Password was changed."
    else
      flash[:error] = "Password not changed."
    end
    bypass_sign_in(@user)
    redirect_to edit_account_password_path
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
  end

end