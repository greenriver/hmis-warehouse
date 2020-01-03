###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# originally from https://github.com/gitlabhq/gitlabhq/blob/master/app/controllers/concerns/authenticates_with_two_factor.rb

# frozen_string_literal: true

# == AuthenticatesWithTwoFactor
#
# Controller concern to handle two-factor authentication
#
# Upon inclusion, skips `require_no_authentication` on `:create`.
module AuthenticatesWithTwoFactor
  extend ActiveSupport::Concern

  # Store the user's ID in the session for later retrieval and render the
  # two factor code prompt
  #
  # The user must have been authenticated with a valid login and password
  # before calling this method!
  #
  # user - User record
  #
  # Returns nil
  def prompt_for_two_factor(user)
    # Set @user for Devise views
    @user = user
    return locked_user_redirect(user) unless user.active?

    session[:otp_user_id] = user.id
    render 'devise/sessions/two_factor'
  end

  def locked_user_redirect(*)
    flash.now[:alert] = _('Invalid Email or password')
    render 'devise/sessions/new'
  end

  def authenticate_with_two_factor
    self.resource = find_user
    user = resource
    return locked_user_redirect(user) unless user.active?

    if user_params[:otp_attempt].present? && session[:otp_user_id]
      authenticate_with_two_factor_via_otp(user)
    elsif user&.valid_password?(user_params[:password])
      prompt_for_two_factor(user)
    end
  end

  private def authenticate_with_two_factor_via_otp(user)
    if valid_otp_attempt?(user) || valid_backup_code_attempt?(user)
      # Remove any lingering user data from login
      session.delete(:otp_user_id)

      user.save!
      sign_in(user, message: :two_factor_authenticated, event: :authentication)
    else
      user.increment_failed_attempts
      Rails.logger.info("Failed Login: user=#{user.email} ip=#{request.remote_ip} method=OTP")
      flash.now[:alert] = _('Invalid two-factor code.')
      prompt_for_two_factor(user)
    end
  end
end
