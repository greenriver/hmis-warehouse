###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
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

      if ENV['AWS_COGNITO_POOL_ID'].present? && @user.provider == 'cognito' && @user.uid.present?
        idp = Aws::CognitoIdentityProvider::Client.new
        idp.admin_update_user_attributes(
          username: @user.uid,
          user_pool_id: ENV['AWS_COGNITO_POOL_ID'],
          user_attributes: [
            {
              name: 'given_name',
              value: @user.first_name,
            },
            {
              name: 'family_name',
              value: @user.last_name,
            },
            {
              name: 'phone_number',
              value: @user.phone,
            },
          ],
        )
      end

      bypass_sign_in(@user)
    end
    redirect_to edit_account_path
  end

  def locations
    @locations = @user.login_activities.order(created_at: :desc).
      page(params[:page]).per(50)
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
