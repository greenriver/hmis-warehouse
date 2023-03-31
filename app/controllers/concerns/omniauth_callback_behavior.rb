###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# originally from https://github.com/gitlabhq/gitlabhq/blob/master/app/controllers/concerns/authenticates_with_two_factor.rb

# frozen_string_literal: true

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

  def passthru
    # Just send them to the home page for now instead
    # of showing the ugly text messsage

    redirect_to home_path
  end

  # configured in omniauth initializer
  def failure
    log('failure')
    redirect_to home_path + '?sso_failed=1'
  end

  protected

  def home_path
    root_path
  end

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
