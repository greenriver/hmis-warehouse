class AccountsController < ApplicationController
  before_action :set_user

  def edit
  end

  def update
    changed_notes = []
    if @user.first_name != account_params[:first_name] || @user.last_name != account_params[:last_name]
      changed_notes << "Account name was updated."
    end
    if @user.email_schedule != account_params[:email_schedule]
      changed_notes << "Email schedule was updated."
    end
    if @user.phone != account_params[:phone]
      changed_notes << "Phone number was updated."
    end
    if @user.agency != account_params[:agency]
      changed_notes << "Agency name was updated."
    end

    if changed_notes.present?
      flash[:notice] = changed_notes.join(' ')
      @user.update(account_params)
      bypass_sign_in(@user)
    end
    redirect_to edit_account_path
  end

  private def account_params
    params.require(:user).
      permit(
        :first_name,
        :last_name,
        :phone,
        :agency,
        :email_schedule,
      )
  end

  private def set_user
    @user = current_user
  end

end
