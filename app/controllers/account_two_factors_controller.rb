###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class AccountTwoFactorsController < ApplicationController
  include AjaxModalRails::Controller
  # before_action :authenticate_user!
  before_action :set_user

  def edit
    @user.set_initial_two_factor_secret!
    render 'accounts/edit'
  end

  # used to create and display backup codes
  def show
    @codes = @user.generate_otp_backup_codes!
    @user.save!
  end

  def update
    if valid_otp_attempt?
      @user.update(confirmed_2fa: @user.confirmed_2fa + 1)
      if @user.confirmed_2fa > 1
        flash[:notice] = "Nice work! Two-Factor Authentication has been enabled, you'll need to use it to login from now on."
        flash[:new_2fa] = true
        @user.update(otp_required_for_login: true)
      end
    else
      flash[:error] = 'The code submitted was invalid'
    end
    redirect_to edit_account_two_factor_path
  end

  def destroy
    @user.disable_2fa!
    redirect_to edit_account_two_factor_path
  end

  def users_warehouse_path
    @user.my_root_path
  end
  helper_method :users_warehouse_path

  def new_2fa?
    flash[:new_2fa] || false
  end
  helper_method :new_2fa?

  def remove_device
    @user.two_factors_memorized_devices.find(params[:device_id]).destroy!
    redirect_to edit_account_two_factor_path
  end

  private def account_params
    params.require(:user).
      permit(
        :otp_attempt,
      )
  end

  private def set_user
    @user = current_user
  end

  private def valid_otp_attempt?
    @user.validate_and_consume_otp!(clean_code)
  end

  private def clean_code
    account_params[:otp_attempt].gsub(/[^0-9a-z]/, '')
  end
end
