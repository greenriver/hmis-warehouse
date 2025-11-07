###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Concern providing JWT-based current_user functionality for controllers.
#
# Replaces Devise's current_user with JWT-based authentication.
# Provides authenticate_user! method that validates JWT and sets current_user.
module CurrentUser
  extend ActiveSupport::Concern

  included do
    # Get the current authenticated user from JWT token.
    #
    # Also ensures authentication source exists for the user (only once per request).
    # This handles cases where users existed before IDP integration.
    #
    # If impersonation is active, returns the impersonated user instead of the true user.
    #
    # @return [User, nil] Current user (or impersonated user) or nil if not authenticated
    def current_user
      @current_user ||= authenticated_user_from_jwt(user_class: User)
    end
    helper_method :current_user

    # Get warden-compatible proxy for backward compatibility.
    #
    # @return [WardenProxy] Proxy that provides warden-like interface
    def warden
      @warden ||= WardenProxy.new(current_user, session: session)
    end

    # Authenticate user via JWT token.
    #
    # Redirects to sign-in page if authentication fails.
    # Can be overridden in subclasses for different behavior (e.g., JSON responses).
    #
    # @raise [ActionController::RedirectBackError] if user is not authenticated
    def authenticate_user!
      user = authenticated_user_from_jwt(user_class: User)
      unless user
        handle_unauthenticated
        return
      end

      # Ensure user is active and eligible for authentication
      unless user.active_for_authentication?
        handle_inactive_user(user)
        return
      end

      @current_user = user
    end

    # Check if user is signed in.
    #
    # Compatible with Devise's user_signed_in? helper.
    #
    # @return [Boolean] true if user is authenticated
    def user_signed_in?
      current_user.present?
    end
    helper_method :user_signed_in?

    # Get the true user (when impersonating).
    #
    # Returns the actual authenticated user from JWT, not the impersonated user.
    # If not impersonating, returns the current_user.
    #
    # @return [User, nil] True user or nil if not authenticated
    def true_user
      return nil unless current_user

      impersonation_manager = ImpersonationManager.new(session&.id)
      impersonation_data = impersonation_manager.get
      return current_user unless impersonation_data && impersonation_data[:true_user_id].present?

      true_user_record = User.find_by(id: impersonation_data[:true_user_id])
      true_user_record || current_user
    end
    helper_method :true_user

    # Check if currently impersonating another user.
    #
    # @return [Boolean] true if impersonating, false otherwise
    def impersonating?
      return false unless current_user

      impersonation_manager = ImpersonationManager.new(session&.id)
      impersonation_data = impersonation_manager.get
      return false unless impersonation_data && impersonation_data[:impersonated_user_id].present?

      # Verify the impersonated user matches current_user
      impersonation_data[:impersonated_user_id] == current_user.id
    end
    helper_method :impersonating?

    private

    # Get JWT helper for the current request.
    #
    # @return [JwtHelper, nil] JwtHelper instance or nil if no token present
    def jwt_helper_for_request
      @jwt_helper_for_request ||= JwtHelper.new(access_token: request.headers['HTTP_X_FORWARDED_ACCESS_TOKEN'])
    end

    # Ensure UserAuthenticationSource exists for the user.
    #
    # This handles cases where users existed before IDP integration.
    # Only creates/updates the auth source if it doesn't exist or needs updating.
    # Uses memoization to ensure it only runs once per request.
    #
    # @param user [User] User instance
    # @param jwt_helper [JwtHelper] JwtHelper instance with validated token
    def ensure_authentication_source(user, jwt_helper)
      return if @auth_source_ensured

      connector_id = jwt_helper.connector_id
      connector_user_id = jwt_helper.connector_user_id

      return if connector_id.blank? || connector_user_id.blank?

      auth_source = user.user_authentication_sources.with_deleted.find_or_initialize_by(
        connector_id: connector_id,
        connector_user_id: connector_user_id,
      )

      # Only save if it's a new record or was soft-deleted
      if auth_source.new_record? || auth_source.deleted?
        auth_source.enabled = true
        auth_source.save!
        auth_source.restore if auth_source.deleted?
      end

      # Update last_connector_id if this is a different connector
      user.update_column(:last_connector_id, connector_id) if user.last_connector_id != connector_id

      @auth_source_ensured = true
    end

    # Validate impersonation permissions.
    #
    # Checks that the true user has permission to impersonate and that the
    # impersonated user can be impersonated by the true user.
    #
    # @param true_user [User] The user who is impersonating
    # @param impersonated_user [User] The user being impersonated
    # @return [Boolean] true if impersonation is allowed, false otherwise
    def validate_impersonation_permissions(true_user, impersonated_user)
      return false unless true_user&.can_impersonate_users?
      return false unless impersonated_user&.impersonateable_by?(true_user)

      true
    end

    # Get authenticated user from JWT with impersonation support.
    #
    # This is a generic method that can be used by both User and Hmis::User controllers.
    # It handles JWT validation, authentication source creation, and impersonation logic.
    #
    # @param user_class [Class] The user class to return (User or Hmis::User)
    # @return [User, Hmis::User, nil] Authenticated user (or impersonated user) or nil
    def authenticated_user_from_jwt(user_class: User)
      jwt_helper = jwt_helper_for_request
      return nil unless jwt_helper&.token? && jwt_helper.validate!

      authenticated_user = User.find_from_jwt(jwt_helper)
      return nil unless authenticated_user

      # Cast to requested user class if different (e.g., Hmis::User)
      user = if user_class == User
        authenticated_user
      else
        user_class.find_by(id: authenticated_user.id)
      end
      return nil unless user

      # Ensure authentication source exists (only once per request)
      ensure_authentication_source(authenticated_user, jwt_helper) unless @auth_source_ensured

      # Check for impersonation state
      impersonation_manager = ImpersonationManager.new(session&.id)
      impersonation_data = impersonation_manager.get
      if impersonation_data && impersonation_data[:impersonated_user_id].present?
        # Validate permissions on every request
        true_user = User.find_by(id: impersonation_data[:true_user_id])
        impersonated_user = user_class.find_by(id: impersonation_data[:impersonated_user_id])

        return impersonated_user if true_user && impersonated_user && validate_impersonation_permissions(true_user, impersonated_user)

        # Clear invalid impersonation
        impersonation_manager.clear
        return user
      end

      user
    end

    # Handle unauthenticated user.
    #
    # Captures the original request URL and redirects to OAuth2-proxy sign-in
    # with the redirect URL preserved via `rd` query parameter.
    #
    # Override in subclasses for custom behavior (e.g., JSON responses).
    def handle_unauthenticated
      original_url = RedirectUrlHelper.capture_original_request_url(
        request: request,
        session_id: session&.id&.to_s,
      )
      redirect_to helpers.oauth2_sign_in_path(redirect_to: original_url)
    end

    # Handle inactive user.
    #
    # Captures the original request URL and redirects to OAuth2-proxy sign-in
    # with the redirect URL preserved via `rd` query parameter.
    #
    # Override in subclasses for custom behavior.
    #
    # @param _user [User] User instance that failed authentication checks
    def handle_inactive_user(_user)
      original_url = RedirectUrlHelper.capture_original_request_url(
        request: request,
        session_id: session&.id&.to_s,
      )
      redirect_to helpers.oauth2_sign_in_path(redirect_to: original_url), alert: 'Your account has been deactivated.'
    end
  end
end
