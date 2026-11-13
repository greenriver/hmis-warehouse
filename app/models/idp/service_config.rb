###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Idp
  # Persists IDP service-account credentials so they can be managed in the UI
  # instead of hardcoded in ENV variables.
  #
  # provider vs connector_id:
  #   provider     — the IDP type (e.g. 'keycloak'); picks the service class via
  #                  Idp::ServiceFactory.
  #   connector_id — the routing key the auth proxy sends in the token. Unique per
  #                  active config, so two realms of one provider are separate
  #                  configs. UserAuthenticationSource joins back here on it.
  #
  # Each provider's service translates these columns into its own config keys in
  # .from_config.
  #
  # manage_users:
  #   Whether we have admin/manage-API access to this IdP. True (the default) is an
  #   IdP we operate; false is authenticate-only — a customer-operated Keycloak, or a
  #   service account that connects but lacks the manage-users role.
  # browser_url / account_client_id:
  #   Per-realm browser origin and account OIDC client for self-service deep-links.
  #   Seeded once from ENV; the row is authoritative thereafter (no request-time ENV).
  class ServiceConfig < ApplicationRecord
    self.table_name = 'idp_service_configs'
    acts_as_paranoid

    attr_encrypted :service_token, key: ENV['ENCRYPTION_KEY'][0..31], attribute: 'encrypted_service_token'

    validates :provider, presence: true
    validates :connector_id, presence: true, uniqueness: { scope: [:active, :deleted_at] }
    validates :name, presence: true
    validates :api_url, presence: true
    validates :service_token, presence: true
    validate :validate_provider
    # Active-only: for_connector builds from .active rows, so a blank-key row only breaks
    # once active. Scoping here lets us park an inactive, half-filled draft and finish it
    # before turning it on.
    validate :validate_provider_config, if: :active?

    scope :active, -> { where(active: true) }

    # Materialize the Keycloak config row from ENV once, so the row is the single source of
    # truth at request time (Idp::ServiceFactory no longer reads KEYCLOAK_*). Runs on every
    # deploy via SeedMaker, so it must be idempotent and must never clobber a UI credential edit.
    #
    # Create-only (find_or_create_by, no update block): ENV is a one-time bootstrap; after the
    # row exists, credential rotation is a UI/DB operation and a re-seed must not overwrite it.
    # with_deleted keys the lookup so a soft-deleted row is found (not resurrected) and a
    # deactivated (active: false) row is left untouched, preserving the off-switch across re-seeds.
    def self.bootstrap_from_env
      return unless AuthMethod.jwt?

      # Require all four core build keys, not just API_URL+SECRET: validate_provider_config rejects
      # an active row missing realm/client_id, so a partial ENV would make create raise
      # RecordInvalid and break the deploy. Missing keys stay a no-op (external IdPs have no
      # KEYCLOAK_* at all).
      return unless ENV['KEYCLOAK_API_URL'].present? &&
        ENV['KEYCLOAK_REALM'].present? &&
        ENV['KEYCLOAK_SERVICE_CLIENT_ID'].present? &&
        ENV['KEYCLOAK_SERVICE_CLIENT_SECRET'].present?

      connector_id = ENV.fetch('KEYCLOAK_CONNECTOR_ID', 'keycloak')

      with_deleted.find_or_create_by(connector_id: connector_id) do |config|
        config.provider = 'keycloak'
        config.name = 'Keycloak (seeded from ENV)'
        config.api_url = ENV['KEYCLOAK_API_URL']
        config.keycloak_realm = ENV['KEYCLOAK_REALM']
        config.client_id = ENV['KEYCLOAK_SERVICE_CLIENT_ID']
        config.service_token = ENV['KEYCLOAK_SERVICE_CLIENT_SECRET']
        config.browser_url = ENV['KEYCLOAK_PUBLIC_URL']
        config.account_client_id = ENV['KEYCLOAK_ACCOUNT_CLIENT_ID']
      end
    end

    # @return [Class] the service class for this provider (e.g. Idp::KeycloakService)
    def service_class
      klass = Idp::ServiceFactory.services[provider.to_s]
      raise(Idp::ServiceError.new("Unknown provider: #{provider}", operation: :service_class)) unless klass

      klass
    end

    # @return [Idp::Service] service instance configured with stored credentials
    def to_service
      service_class.from_config(self)
    end

    private

    def validate_provider
      return if provider.blank? # presence validation handles this

      return if Idp::ServiceFactory.services.key?(provider.to_s)

      errors.add(:provider, "unknown provider: #{provider}")
    end

    # Each provider's .from_config reads a specific set of these columns; without them an
    # active row saves cleanly then raises Idp::ServiceError at every service build.
    def validate_provider_config
      return unless Idp::ServiceFactory.services.key?(provider.to_s) # validate_provider handles unknown

      service_class.validate_config(self)
    end
  end
end
