###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include AuthenticatesWithTwoFactor
  USER_TYPES = [HMIS_USER_TYPE = 'hmis_user'.freeze, WH_USER_TYPE = 'user'.freeze].freeze

  def okta
    log("begin user_type:#{user_type}")

    user = user_scope.from_omniauth request.env['omniauth.auth']

    log("found #{user.class.name}##{user.id}")
    if user.two_factor_enabled?
      log '2fa'
      return locked_user_redirect(user) unless user.active?

      # bypass 2fa if user has device
      if using_memorized_device?(user) && bypass_2fa_enabled?
        two_factor_successful(user)
        handle_success(user)
      else
        prompt_for_two_factor(user)
      end
    else
      log('sign-in')
      sign_in(user_type.to_sym, user, event: :authentication)

      handle_success(user)
    end
  end

  def passthru
    # Just send them to the home page for now instead
    # of showing the ugly text messsage

    redirect_to root_path
  end

  def failure
    log('failure')
    case user_type
    when HMIS_USER_TYPE
      redirect_to hmis_host_url + '?sso_failed=1'
    when WH_USER_TYPE
      super
    else
      raise
    end
  end

  protected

  def handle_success(user)
    log('success')
    case user_type
    when HMIS_USER_TYPE
      set_csrf_cookie
      redirect_to hmis_host_url
    when WH_USER_TYPE
      set_flash_message(:notice, :success, kind: 'OKTA') if is_navigational_format?
      redirect_to after_sign_in_path_for(user)
    else
      raise
    end
  end

  def hmis_host_url
    host = ENV.fetch('HMIS_HOSTNAME')
    "https://#{host}"
  end

  def set_csrf_cookie
    cookies['CSRF-Token'] = form_authenticity_token
  end

  def user_type
    value = cookies.signed[:user_type]
    value.presence_in(USER_TYPES) || WH_USER_TYPE
  end

  def user_scope
    case user_type
    when HMIS_USER_TYPE
      Hmis::User
    when WH_USER_TYPE
      User
    else
      raise
    end
  end

  def log(msg)
    method_name = caller_locations(1, 1)[0].label
    Rails.logger.debug "##{method_name} #{msg}"
  end
end
