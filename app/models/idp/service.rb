###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Idp
  # Base interface for Identity Provider (IDP) services.
  #
  # This abstract class defines the contract that all IDP service implementations must follow.
  # IDP services handle user management operations like creating users and updating profiles.
  #
  # To add support for a new IDP:
  # 1. Create a new class inheriting from Idp::Service
  # 2. Implement all required methods
  # 3. Register the service in Idp::ServiceFactory
  #
  # @abstract Subclass and implement all methods to create a concrete IDP service.
  class Service
    attr_reader :config

    def initialize(config: nil)
      @config = config || default_config
    end

    # Create a new user in the IDP.
    #
    # @param email [String] User's email address
    # @param first_name [String] User's first name
    # @param last_name [String] User's last name
    # @param phone [String, nil] User's phone number (optional)
    # @return [Hash] Result hash with :success (Boolean) and :connector_user_id (String, nil)
    #   Example: { success: true, connector_user_id: 'user-123' }
    # @raise [Idp::ServiceError] if user creation fails
    def create_user(email:, first_name:, last_name:, phone: nil)
      raise NotImplementedError, "#{self.class.name} must implement #create_user"
    end

    # Update a user's profile in the IDP.
    #
    # @param user_id [String] IDP user ID
    # @param attributes [Hash] Hash of attributes to update (e.g., { first_name: 'John', email: 'john@example.com' })
    # @return [Hash] Updated user data
    # @raise [Idp::ServiceError] if update fails
    def update_user(user_id:, attributes:)
      raise NotImplementedError, "#{self.class.name} must implement #update_user"
    end

    # Fetch user data from the IDP.
    #
    # @param user_id [String] IDP user ID
    # @return [Hash] User data
    # @raise [Idp::ServiceError] if user not found
    def get_user(user_id:)
      raise NotImplementedError, "#{self.class.name} must implement #get_user"
    end

    # Reactivate a user account in the IDP.
    #
    # @param user_id [String] IDP user ID
    # @return [Boolean] true if successful
    # @raise [Idp::ServiceError] if reactivation fails or not supported
    def reactivate_user(user_id:)
      raise NotImplementedError, "#{self.class.name} must implement #reactivate_user"
    end

    # Return a human-readable name for this IDP.
    #
    # @return [String] IDP name (e.g., "Zitadel", "Okta")
    def idp_name
      raise NotImplementedError, "#{self.class.name} must implement #idp_name"
    end

    # Check if this IDP supports user management operations.
    #
    # @return [Boolean] true if IDP supports creating/updating users
    def supports_user_management?
      false
    end

    # Check if this IDP supports profile field updates (name, email, phone).
    #
    # @return [Boolean] true if IDP supports updating profile fields
    def supports_profile_updates?
      false
    end

    # Generate OIDC RP-Initiated Logout URL for this IDP.
    #
    # By default, returns the post_logout_redirect_uri (typically oauth2-proxy sign_out).
    # IDP implementations that support OIDC logout should override this to return
    # their IDP-specific logout URL.
    #
    # @param post_logout_redirect_uri [String] Where to redirect after logout (typically oauth2-proxy sign_out)
    # @return [String] Logout URL
    def logout_url(post_logout_redirect_uri:)
      post_logout_redirect_uri
    end

    protected

    def default_config
      {}
    end
  end

  # Custom error class for IDP service operations.
  class ServiceError < StandardError
    attr_reader :idp_name, :operation

    def initialize(message, idp_name: nil, operation: nil)
      super(message)
      @idp_name = idp_name
      @operation = operation
    end
  end
end
