###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# mixin for okta callbacks,
# note failure is configured in omniauth initializer
module OmniauthCallbackBehavior
  extend ActiveSupport::Concern
  include AuthenticatesWithTwoFactor

  def okta
    log("begin user_type:#{user_scope.name}")

    auth = request.env['omniauth.auth']
    provider = auth.provider
    user = OmniauthUserProvisioner.new.perform(auth: auth, user_scope: user_scope)

    log("found #{user.class.name}##{user.id}")
    if user.two_factor_enabled?
      handle_2fa(user)
    else
      log('sign-in')
      cookies.signed[:active_provider] = provider
      handle_success(user)
    end
  end

  protected

  def log(msg)
    method_name = caller_locations(1, 1)[0].label
    Rails.logger.debug "#{self.class.name}##{method_name} #{msg}"
  end

  def handle_2fa(user)
    log '2fa'
    return locked_user_redirect(user) unless user.active?

    # bypass 2fa if user has device
    if using_memorized_device?(user) && bypass_2fa_enabled?
      two_factor_successful(user)
      handle_success(user)
    else
      prompt_for_two_factor(user)
    end
  end

end
