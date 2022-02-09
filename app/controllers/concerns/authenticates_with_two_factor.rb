###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
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

    # bypass 2fa if user has device
    if using_memorized_device?(user) && bypass_2fa_enabled?
      two_factor_successful(user)
    elsif user_params[:otp_attempt].present? && session[:otp_user_id]
      authenticate_with_two_factor_via_otp(user)
    elsif user&.valid_password?(user_params[:password])
      prompt_for_two_factor(user)
    end
  end

  private def authenticate_with_two_factor_via_otp(user)
    if valid_otp_attempt?(user) || valid_backup_code_attempt?(user)
      two_factor_successful(user)
    else
      user.increment_failed_attempts
      Rails.logger.info("Failed Login: user=#{user.email} ip=#{request.remote_ip} method=OTP")
      flash.now[:alert] = _('Invalid two-factor code.')
      prompt_for_two_factor(user)
    end
  end

  private def add_2fa_device(user, name)
    uuid = SecureRandom.uuid
    expiration = TwoFactorsMemorizedDevice.expiration_timestamp

    user.two_factors_memorized_devices.create!(
      uuid: uuid,
      name: name,
      session_id: session.id,
      log_in_ip: request.remote_ip,
      expires_at: expiration,
    )

    # set cookie and add to two_factors_memorized_devices list
    cookies.encrypted[:memorized_device] = { value: uuid, expires: expiration }
  end

  private def using_memorized_device?(user)
    cookie_uuid = cookies.encrypted[:memorized_device]
    return false unless cookie_uuid

    # find if cookie exist in active
    user.two_factors_memorized_devices.active.exists?(uuid: cookie_uuid)
  end

  private def two_factor_successful(user)
    # Remove any lingering user data from login
    session.delete(:otp_user_id)

    user.save!
    sign_in(user, message: :two_factor_authenticated, event: :authentication)

    # add 2fa device if true
    return unless user_params[:remember_device] == 'true' && bypass_2fa_enabled?

    # force a device name, even if none provided
    browser = Browser.new(request.user_agent)
    device_name = user_params[:device_name].presence || "#{browser.name} #{browser.platform.name}"
    add_2fa_device(user, device_name)
  end
end
