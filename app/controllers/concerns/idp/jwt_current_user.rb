###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# JWT for warehouse controllers. Provides devise-compatible methods
module Idp::JwtCurrentUser
  extend ActiveSupport::Concern
  include Idp::JwtAuthentication

  included do
    def current_user
      @current_user ||= idp_authenticated_user_from_jwt(user_class: User) || idp_background_render_user
    end
    helper_method :current_user

    # Background renders carry no forwarded JWT: WardenProxyFactory hands the user's proxy to
    # ActionController::Renderer as the 'warden' rack key. No Warden middleware runs on the JWT
    # arm, so only those renderers can populate the key.
    private def idp_background_render_user
      proxy = request&.env&.dig('warden')
      proxy.user(:user) if proxy.is_a?(Idp::WardenProxy)
    end

    def warden
      @warden ||= Idp::WardenProxy.new(current_user, session: session)
    end

    def authenticate_user!
      if current_user
        idp_schedule_user_sync
        return
      end

      # A deactivated user holds a valid IdP token
      return idp_handle_deactivated if idp_token_holder && !idp_token_holder.active?

      idp_handle_unauthenticated
    end

    # If a deactivated user reaches the app with a valid JWT, show a warning page instead of
    # letting them land on the public homepage as we do for unauthenticated users.
    def reject_deactivated_user!
      return unless request.format.html?
      return if current_user
      return unless idp_token_holder && !idp_token_holder.active?

      idp_handle_deactivated
    end

    def user_signed_in?
      current_user.present?
    end
    helper_method :user_signed_in?

    # A duration the inactivity modal's JS anchors to the browser clock — never the absolute
    # server-issued expiry, which server/browser clock skew would read as already expired.
    def inactive_session_countdown_values
      return {} unless current_user && (expires_at = user_session_expires_at)

      { session_remaining_secs_value: (expires_at - Time.current).to_i }
    end
    helper_method :inactive_session_countdown_values

    # The actual authenticated user from the JWT, not the impersonated user.
    def true_user
      return nil unless current_user

      impersonation_data = impersonation_manager.get
      return current_user unless impersonation_data && impersonation_data[:true_user_id].present?

      # Use same class as current_user to ensure permissions load correctly
      true_user_record = current_user.class.find_by(id: impersonation_data[:true_user_id])
      true_user_record || current_user
    end
    helper_method :true_user

    def impersonating?
      return false unless current_user

      impersonation_data = impersonation_manager.get
      return false unless impersonation_data && impersonation_data[:impersonated_user_id].present?

      impersonation_data[:impersonated_user_id] == current_user.id
    end
    helper_method :impersonating?

    # Impersonation write-side under JWT (replaces pretender's impersonate_user).
    # authorization check is performed by the controller's before_action
    def impersonate_user(user)
      impersonation_manager.store(true_user.id, user.id)
      @current_user = user
    end

    def stop_impersonating_user
      real_user = true_user
      impersonation_manager.clear
      @current_user = real_user
    end

    private

    def info_for_paper_trail
      {
        user_id: true_user&.id, # under devise, we use warden&.user&.id which is true_user_id
        session_id: session&.id&.to_s,
        request_id: request.uuid,
      }
    end

    def skip_timeout
      nil # no-op for jwt
    end

    def enforce_2fa!
      nil # no-op for jwt: L2/MFA assurance is gated upstream by the IdP, not the warehouse
    end

    # Devise (unloaded on this arm) is what defines devise_controller?; stub it false so the
    # Devise-only before_action :configure_permitted_parameters no-ops instead of raising.
    def devise_controller?
      false
    end
  end
end
