###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# All Devise/Warden-path controller behavior, isolated here so the Devise teardown is a single-file
# delete. Included into ApplicationController only under AuthMethod.devise?.
#
# NOTE: the before_action registrations that drive enforce_2fa! / skip_timeout /
# configure_permitted_parameters deliberately live in ApplicationController, not in this concern's
# `included` block — see the filter-order rationale there. `impersonates :user` likewise stays
# Devise-only in ApplicationController's auth-strategy branch.
module DeviseCurrentUser
  extend ActiveSupport::Concern

  # Methods live inside `included do` so the `helper_method` calls resolve
  included do
    protected

    def configure_permitted_parameters
      devise_parameter_sanitizer.permit(:sign_in, keys: [:otp_attempt, :remember_device, :device_name])
    end

    # Redirect to window page after signin if you have
    # no where else to go (and you can see it)
    def after_sign_in_path_for(resource)
      # alert users if their password has been compromised
      set_flash_message! :alert, :warn_pwned if resource.respond_to?(:pwned?) && resource.pwned?

      last_url = session['user_return_to']
      if last_url.present?
        last_url
      else
        current_user&.my_root_path || root_path
      end
    end

    def after_sign_out_path_for(_scope)
      user = request.env['last_user']
      if user
        provider = cookies.signed[:active_provider]
        if provider
          # If a provider exists, user is from Okta, due to the complexity of single log-out, we'll
          # just log you out of okta in this case
          identity = OauthIdentity.for_user(user).where(provider: provider).first
          identity&.idp_signout_url(post_logout_redirect_uri: root_url) || root_url
        else
          # If no provider exists, attempt to log the user out of superset (if they have access)
          # this will redirect back to the warehouse
          superset_logout = "#{Superset.superset_base_url}/logout/?next=#{CGI.escape(root_url)}" if RailsDrivers.loaded.include?(:superset) && Superset.available_to_user?(user)
          superset_logout || root_url
        end
      else
        root_url
      end
    end

    # If a user must have Two-factor authentication turned on, only let them go
    # to their 2FA page and their account page
    def enforce_2fa!
      return unless current_user
      return unless current_user.enforced_2fa?
      return if current_user.two_factor_enabled?
      return if allowed_setup_controllers

      flash[:alert] = 'Two factor authentication must be enabled for this account.'
      redirect_to edit_account_two_factor_path
    end

    def bypass_2fa_enabled?
      GrdaWarehouse::Config.get(:bypass_2fa_duration)&.positive?
    end
    helper_method :bypass_2fa_enabled?

    # FIXME - this maybe dead code, can't find any callers
    # the identity authenticated for the current session
    # @example get the okta user id
    #   current_user_identity&.uid
    # @return [OauthIdentity, nil]
    def current_user_identity
      return nil unless current_user

      provider = cookies.signed[:active_provider]
      return nil unless provider

      @current_user_identity ||= OauthIdentity.for_user(current_user).where(provider: provider).first
    end
    helper_method :current_user_identity

    # don't extend the user's session if its an ajax request.
    def skip_timeout
      request.env['devise.skip_trackable'] = true if request.xhr?
    end

    def devise_mapping
      @devise_mapping ||= Devise.mappings[:user]
    end
    helper_method :devise_mapping

    def user_session_expires_at
      Time.current + (Devise.timeout_in - (Time.now.utc - (session['last_request_at'].presence || 0)).to_i)
    end
    helper_method :user_session_expires_at
  end
end
