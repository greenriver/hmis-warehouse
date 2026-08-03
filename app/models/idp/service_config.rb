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

    scope :active, -> { where(active: true) }

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
  end
end
