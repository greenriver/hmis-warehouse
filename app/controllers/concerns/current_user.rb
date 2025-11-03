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
    # @return [User, nil] Current user or nil if not authenticated
    def current_user
      @current_user ||= begin
        jwt_helper = jwt_helper_for_request
        return nil unless jwt_helper&.token? && jwt_helper.validate!

        User.find_from_jwt(jwt_helper)
      end
    end
    helper_method :current_user

    # Get warden-compatible proxy for backward compatibility.
    #
    # @return [WardenProxy] Proxy that provides warden-like interface
    def warden
      @warden ||= WardenProxy.new(current_user)
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
      redirect_to '/oauth2/sign_in'
    end

    # Handle inactive user.
    #
    # Override in subclasses for custom behavior.
    def handle_inactive_user
      redirect_to '/oauth2/sign_in', alert: 'Your account has been deactivated.'
    end
  end
end
