###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class AccountsController < ApplicationController
  before_action :set_user

  def edit
    @user.set_initial_two_factor_secret!
  end

  def update
    changed_notes = []
    changed_notes << 'Account name was updated.' if @user.first_name != account_params[:first_name] || @user.last_name != account_params[:last_name]
    changed_notes << 'Email schedule was updated.' if @user.email_schedule != account_params[:email_schedule]
    changed_notes << 'Phone number was updated.' if @user.phone != account_params[:phone]
    changed_notes << 'Agency name was updated.' if @user.agency_id.to_s != account_params[:agency].to_s && account_params[:agency].present?

    if changed_notes.present?
      flash[:notice] = changed_notes.join(' ')
      @user.update(account_params)
      bypass_sign_in(@user)
    end
    redirect_to edit_account_path
  end

  def locations
    @pagy, @locations = pagy(@user.login_activities.order(created_at: :desc), items: 50)
  end

  private def account_params
    params.require(:user).
      permit(
        :first_name,
        :last_name,
        :phone,
        :email_schedule,
        :otp_required_for_login,
      )
  end

  private def set_user
    @user = current_user
  end
end
