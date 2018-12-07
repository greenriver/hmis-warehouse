class AccountEmailsController < ApplicationController
  # before_action :authenticate_user!
  before_action :set_user

  def edit
    render "accounts/edit"
  end

  def update
    changed_notes = []
    if @user.email != account_params[:email]
      changed_notes << "Account email was updated, check your inbox for a confirmation link."
    end

    if @user.update_with_password(account_params)
      flash[:notice] = changed_notes.join(' ')
      bypass_sign_in(@user)
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
  end

end