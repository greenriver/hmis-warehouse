###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Users::SessionsController < Devise::SessionsController
  include AuthenticatesWithTwoFactor
  prepend_before_action(
    :authenticate_with_two_factor,
    if: -> { action_name == 'create' && two_factor_enabled? },
  )

  def create
    super do |resource|
      # User has successfully signed in, so clear any unused reset token
      resource.update(reset_password_token: nil, reset_password_sent_at: nil) if resource.reset_password_token.present?
    end
  end

  def destroy
    request.env['last_user'] = current_user

    super
  end

  # configure auto_session_timeout
  def active
    respond_to do |format|
      format.json do
        render_session_status
      end
      format.html do
        redirect_to(root_path)
      end
    end
  end

  def timeout
    flash[:notice] = 'Your session expired; you have been logged out.'
    redirect_to root_path
  end

  def find_user
    if session[:otp_user_id]
      User.find(session[:otp_user_id])
    elsif user_params[:email]
      User.find_by(email: user_params[:email])
    end
  end

  def user_params
    params.require(:user).permit(:email, :password, :otp_attempt, :remember_device, :device_name)
  end

  def two_factor_enabled?
    find_user&.two_factor_enabled?
  end

  def training_complete?
    find_user&.training_complete?
  end

  def valid_otp_attempt?(user)
    user.validate_and_consume_otp!(clean_code)
  end

  def valid_backup_code_attempt?(user)
    user.invalidate_otp_backup_code!(clean_code)
  end

  private def clean_code
    user_params[:otp_attempt].gsub(/[^0-9a-z]/, '')
  end
end
