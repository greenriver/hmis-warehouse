###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Warden-compatible proxy for JWT-based authentication.
#
# Provides a warden-like interface for code that expects warden.user to be available.
# This allows existing code that uses warden to continue working without modification.
class WardenProxy
  def initialize(user, session: nil)
    @user = user
    @session = session
  end

  # Get the authenticated user for the given scope.
  #
  # Compatible with warden.user(scope: :user)
  #
  # @param scope [Symbol] The scope (typically :user or :hmis_user)
  # @return [User, nil] The authenticated user or nil
  def user(scope: :user)
    return nil unless scope == :user

    @user
  end

  # Check if user is authenticated for the given scope.
  #
  # @param scope [Symbol] The scope (typically :user)
  # @return [Boolean] true if user is authenticated
  def authenticated?(scope: :user)
    scope == :user && @user.present?
  end

  # Check if authentication is successful (alias for authenticated?).
  #
  # Compatible with warden.authenticate?(scope: :user)
  #
  # @param scope [Symbol] The scope (typically :user)
  # @return [Boolean] true if user is authenticated
  def authenticate?(scope: :user)
    authenticated?(scope: scope)
  end

  # Authenticate user (no-op for JWT-based auth).
  #
  # This method exists for compatibility but doesn't do anything
  # since authentication is handled via JWT.
  def authenticate!(*)
    @user
  end

  # Set user (for compatibility with warden API).
  #
  # @param user [User] The user to set
  # @param scope [Symbol] The scope (typically :user)
  # @param store [Boolean] Ignored (for compatibility)
  # @param run_callbacks [Boolean] Ignored (for compatibility)
  def set_user(user, scope: :user, _store: false, _run_callbacks: false)
    @user = user if scope == :user
  end

  # Get session (for compatibility with warden API).
  #
  # Returns the session hash if available, otherwise returns nil.
  # In JWT-based authentication, the session is managed by Rails, not Warden.
  #
  # @param _args [Array] Optional arguments (ignored for compatibility)
  # @return [Hash, nil] Session hash or nil if not available
  def session(*_args)
    @session
  end
end
