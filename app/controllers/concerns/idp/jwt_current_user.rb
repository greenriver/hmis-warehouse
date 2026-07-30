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

    # The same wall authenticate_user! puts up, for the routes that skip it. oauth2-proxy forwards the
    # token on a skip_auth_route as well (that's how /hmis/user.json reports who's signed in), and
    # root is one, so someone whose account was switched off signs in, gets sent to root, and reads
    # the public landing page as a sign-in that silently failed. It's the first thing they see, since
    # root is where the proxy returns them when they didn't start anywhere else.
    #
    # current_user first, not idp_token_holder: resolving it is what stamps the session principal, so
    # the 403 can't render on the previous user's session (see idp_sync_session_principal!).
    #
    # HTML only. A stylesheet or a JSON poll answered with a page tells nobody anything, and the two
    # cases differ in who they'd catch: the no-warehouse-account page is deliberately not here,
    # because on a realm shared with other apps plenty of valid tokens belong to people who simply
    # aren't warehouse users, and the public pages stay public for them.
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
