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
    # @return [User, nil] Current user or nil if not authenticated
    def current_user
      @current_user ||= begin
        jwt_helper = jwt_helper_for_request
        return nil unless jwt_helper&.token? && jwt_helper.validate!

        user = User.find_from_jwt(jwt_helper)
        return nil unless user

        # Ensure authentication source exists (only once per request)
        ensure_authentication_source(user, jwt_helper) unless @auth_source_ensured

        user
      end
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
      jwt_helper = jwt_helper_for_request

      unless jwt_helper&.token? && jwt_helper.validate!
        handle_unauthenticated
        return
      end

      user = User.find_from_jwt(jwt_helper)
      unless user
        handle_unauthenticated
        return
      end

      # Ensure authentication source exists (only once per request)
      ensure_authentication_source(user, jwt_helper) unless @auth_source_ensured

      # Ensure user is active
      unless user.active?
        handle_inactive_user
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
    # @return [User, nil] True user or nil if not impersonating
    def true_user
      # If impersonation is active, return the true user
      # This uses the pretender gem's impersonation functionality
      session[:true_user_id] ? User.find_by(id: session[:true_user_id]) : current_user
    end
    helper_method :true_user

    private

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

    # Get JwtHelper instance for the current request.
    #
    # @return [JwtHelper, nil] JwtHelper instance or nil if no token present
    def jwt_helper_for_request
      access_token = request.headers['HTTP_X_FORWARDED_ACCESS_TOKEN']
      return nil unless access_token.present?

      JwtHelper.new(access_token: access_token)
    end

    # Handle unauthenticated user.
    #
    # Override in subclasses for custom behavior (e.g., JSON responses).
    def handle_unauthenticated
      redirect_to helpers.oauth2_sign_in_path
    end

    # Handle inactive user.
    #
    # Override in subclasses for custom behavior.
    def handle_inactive_user
      redirect_to helpers.oauth2_sign_in_path, alert: 'Your account has been deactivated.'
    end
  end
end
