###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Idp
  # Persists IDP service-account credentials so they can be managed in the UI
  # instead of hardcoded in ENV variables.
  #
  # provider vs connector_id:
  #   provider     — the registered IDP type (e.g. 'keycloak'); picks the service
  #                  class via Idp::ServiceFactory.
  #   connector_id — the routing key the auth proxy sends in the JWT
  #                  (federated_claims.connector_id). Unique per active config, so
  #                  multiple realms/tenants of one provider are distinct configs
  #                  (same provider, different connector_id). UserAuthenticationSource
  #                  joins back here on connector_id to reach the realm + credentials.
  #
  # Column mapping (columns → config keys passed to the service). Each provider's
  # service owns this translation in its .from_config; the reference below is the
  # union across providers.
  #
  # Shared OIDC fields — meaningful for every provider:
  #   api_url        → :api_url        — base URL of the IDP (e.g. http://keycloak:8080)
  #   client_id      → :client_id      — service-account client ID
  #   service_token  → :client_secret  — encrypted service-account secret
  #
  # Provider-specific fields — namespaced; only apply for their connector:
  #   keycloak_realm → :realm          — (Keycloak) realm; required — the service raises if blank
  #   okta_org_id    → :org_id         — (Okta) org identifier (optional)
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
      Idp::ServiceFactory.services[provider.to_s] || raise(
        Idp::ServiceError.new("Unknown provider: #{provider}", operation: :service_class),
      )
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
