###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Idp
  # Abstract contract every IDP backend implements. Subclass and implement the
  # CRUD/capability methods to support a new IDP, then register it in
  # Idp::ServiceFactory.
  class Service
    attr_reader :config

    def initialize(config: nil)
      @config = config || default_config
    end

    # Build a service from a persisted Idp::ServiceConfig, translating its storage
    # columns into this service's config keys. Every registered provider implements it.
    def self.from_config(config)
      raise NotImplementedError, "#{name} must implement .from_config"
    end

    # @return [Hash] { success: Boolean, connector_user_id: String|nil }
    def create_user(email:, first_name:, last_name:, phone: nil)
      raise NotImplementedError, "#{self.class.name} must implement #create_user"
    end

    def update_user(user_id:, attributes:)
      raise NotImplementedError, "#{self.class.name} must implement #update_user"
    end

    def get_user(user_id:)
      raise NotImplementedError, "#{self.class.name} must implement #get_user"
    end

    def reactivate_user(user_id:)
      raise NotImplementedError, "#{self.class.name} must implement #reactivate_user"
    end

    # @return [String] human-readable IDP name (e.g. "Keycloak")
    def idp_name
      raise NotImplementedError, "#{self.class.name} must implement #idp_name"
    end

    def supports_user_management?
      false
    end

    def supports_profile_updates?
      false
    end

    def supports_account_backfill?
      false
    end

    def user_scope
      User.none
    end

    # @return [Hash] { success: Boolean, message: String }
    def test_connection
      {
        success: false,
        message: 'Connection testing not supported for this IDP',
      }
    end

    # OIDC RP-Initiated Logout URL. Defaults to the post-logout redirect; IDPs
    # that support OIDC logout override this.
    def logout_url(post_logout_redirect_uri:, client_id: nil) # rubocop:disable Lint/UnusedMethodArgument
      post_logout_redirect_uri
    end

    # Deep-link to the IDP's self-service credential console (password/2FA).
    # Defaults to nil for IDPs with no such console.
    def account_console_url
      nil
    end

    protected

    def default_config
      {}
    end
  end
end
