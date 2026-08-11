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
      @current_user ||= idp_authenticated_user_from_jwt(user_class: User)
    end
    helper_method :current_user

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

    # Return seconds remaining, not the absolute expiry timestamp: browser/server clock skew
    # would read a server-issued timestamp as already expired.
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
  end
end
