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
  # Column mapping (columns → config keys passed to the service):
  #   api_url        → :api_url        — base URL of the IDP (e.g. http://keycloak:8080)
  #   service_token  → :client_secret  — encrypted service-account secret
  #   org_id         → :org_id         — (optional) organization identifier
  #   project_id     → :project_id     — (optional) project identifier
  #   additional_config (JSONB)         — provider-specific keys merged into the config hash:
  #     Keycloak: { client_id: "…", realm: "…" }
  class ServiceConfig < GrdaWarehouseBase
    self.table_name = 'idp_service_configs'
    acts_as_paranoid

    attr_encrypted :service_token, key: ENV['ENCRYPTION_KEY'][0..31], attribute: 'encrypted_service_token'

    validates :connector_id, presence: true, uniqueness: { scope: [:active, :deleted_at] }
    validates :name, presence: true
    validates :api_url, presence: true
    validates :service_token, presence: true

    scope :active, -> { where(active: true) }

    # Get the service class for this connector
    #
    # @return [Class] The service class (e.g., Idp::KeycloakService)
    def service_class
      Idp::ServiceFactory.services[connector_id.to_s] || Idp::NullService
    end

    # Instantiate the service with this config's stored credentials
    #
    # @return [Idp::Service] Service instance configured with stored credentials
    def to_service
      config_hash = {
        api_url: api_url,
        client_secret: service_token,
        org_id: org_id,
        project_id: project_id,
      }.merge((additional_config || {}).symbolize_keys)

      service_class.new(config: config_hash)
    end

  end
end
