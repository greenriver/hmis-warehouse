###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Idp
  # Model for storing IDP service account credentials
  #
  # Allows administrators to configure service accounts for different IDPs
  # (Zitadel, Okta, Azure AD, etc.) without hardcoding credentials in ENV variables.
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
    # @return [Class] The service class (e.g., Idp::ZitadelService)
    def service_class
      Idp::ServiceFactory.services[connector_id.to_s] || Idp::NullService
    end

    # Instantiate the service with this config's stored credentials
    #
    # @return [Idp::Service] Service instance configured with stored credentials
    def to_service
      config_hash = {
        api_url: api_url,
        service_token: service_token,
        org_id: org_id,
        project_id: project_id,
        additional_config: additional_config || {},
      }

      service_class.new(config: config_hash)
    end
  end
end
