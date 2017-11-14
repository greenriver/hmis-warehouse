class AccountsController < ApplicationController
  before_action :set_user

  def edit
  end

  def update
    changed_notes = []
    if @user.first_name != account_params[:first_name] || @user.last_name != account_params[:last_name]
      changed_notes << "Account name was updated."
    end
    if @user.email != account_params[:email]
      changed_notes << "Account email was updated, check your inbox for a confirmation link."
    end
    if account_params[:password_confirmation].present? && (account_params[:password] == account_params[:password_confirmation])
      changed_notes << "Password was changed. "
    end
    changed_notes << "Account updated." if changed_notes.empty?
    if @user.update_with_password(account_params)
      flash[:notice] = changed_notes.join(' ')

      sign_in(@user, :bypass => true)
      redirect_to edit_account_path
    else
      render 'edit'
    end

  end

  private
    def account_params
      params.require(:user).
        permit(
          :first_name,
          :last_name,
          :email,
          :phone,
          :agency,
          :current_password,
          :password,
          :password_confirmation,
        )
    end

    def set_user
      @user = current_user
    end

end
