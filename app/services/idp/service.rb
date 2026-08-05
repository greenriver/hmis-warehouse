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

    # Validate that a persisted Idp::ServiceConfig carries every column this service's
    # .from_config needs, adding errors to the record for any that are missing. Base is a
    # no-op — providers with required columns override.
    def self.validate_config(record)
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

    # Look up a user in the IdP by email. Returns the provider's user representation (a Hash)
    # or nil when no account matches. Used to link an existing remote account instead of
    # creating a duplicate.
    def find_user_by_email(email:)
      raise NotImplementedError, "#{self.class.name} must implement #find_user_by_email"
    end

    # Ask the IdP to email the user a link that walks them through the given required actions
    # (e.g. ['UPDATE_PASSWORD', 'VERIFY_EMAIL']) — used to let an admin-provisioned account set
    # its own credentials rather than the admin setting a password.
    def send_execute_actions_email(user_id:, actions:)
      raise NotImplementedError, "#{self.class.name} must implement #send_execute_actions_email"
    end

    def reactivate_user(user_id:)
      raise NotImplementedError, "#{self.class.name} must implement #reactivate_user"
    end

    def deactivate_user(user_id:)
      raise NotImplementedError, "#{self.class.name} must implement #deactivate_user"
    end

    def set_required_action(user_id:, actions:)
      raise NotImplementedError, "#{self.class.name} must implement #set_required_action"
    end

    # Guarded by #supports_session_logout?.
    def logout_user_sessions(user_id:)
      raise NotImplementedError, "#{self.class.name} must implement #logout_user_sessions"
    end

    # @return [String] human-readable IDP name (e.g. "Keycloak")
    def idp_name
      raise NotImplementedError, "#{self.class.name} must implement #idp_name"
    end

    def supports_user_management?
      false
    end

    # Whether an admin can provision brand-new accounts through this IdP (create + email a
    # credential-setup link). Distinct from #supports_user_management?, which covers editing
    # existing accounts.
    def supports_user_creation?
      false
    end

    def supports_profile_updates?
      false
    end

    # Whether the user can change their own email address *at the IdP*, with the IdP owning
    # collection and mailbox verification. Distinct from #supports_profile_updates?, which is
    # about the Warehouse pushing an already-committed edit in.
    def supports_email_self_service?
      false
    end

    def supports_account_backfill?
      false
    end

    # Whether this IDP can end a user's sessions through its admin API. Sign-out gates on it: an
    # IDP that only authenticates has no session for us to end.
    def supports_session_logout?
      false
    end

    # @return [Hash] { success: Boolean, message: String }
    def test_connection
      {
        success: false,
        message: 'Connection testing not supported for this IDP',
      }
    end

    # Deep-link to the IDP's self-service credential console (password/2FA).
    # Defaults to nil for IDPs with no such console.
    def account_console_url
      nil
    end

    # Deep-link that drops the current user straight into a single self-service action
    # (e.g. UPDATE_PASSWORD, CONFIGURE_TOTP) and returns them to redirect_uri afterward.
    # Defaults to nil for IDPs that don't support such deep-links.
    def account_action_url(action:, redirect_uri:) # rubocop:disable Lint/UnusedMethodArgument
      nil
    end

    # Address the user asked for but hasn't confirmed yet, for IDPs that hold one alongside the live
    # address. Display only; nil for an IDP with no such concept.
    # @return [String, nil]
    def pending_email(user_id:) # rubocop:disable Lint/UnusedMethodArgument
      nil
    end

    # Takes an already-fetched representation so a caller that holds one — the account page, which
    # just read it to reconcile — needn't spend a second Admin API read.
    # @return [String, nil]
    def pending_email_from_representation(representation) # rubocop:disable Lint/UnusedMethodArgument
      nil
    end

    protected

    def default_config
      {}
    end
  end
end
