###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Idp
  # Factory for obtaining IDP service instances based on connector_id.
  #
  # This factory uses a registry pattern to map connector IDs to their corresponding
  # IDP service implementations. New IDPs can be added by registering their service class.
  #
  # @example Get Zitadel service
  #   service = Idp::ServiceFactory.for_connector('zitadel')
  #   service.create_user(email: 'user@example.com', ...)
  #
  # @example Register a new IDP service
  #   Idp::ServiceFactory.register_idp_service('okta', Idp::OktaService)
  class ServiceFactory
    class << self
      # Registry mapping connector_id to service class.
      attr_reader :services

      # Initialize the registry.
      def initialize_registry
        @services = {} if @services.nil?
      end

      # Register an IDP service class for a given connector_id.
      #
      # @param connector_id [String] The connector ID (e.g., 'zitadel', 'okta')
      # @param service_class [Class] The IDP service class (must inherit from Idp::Service)
      # @raise [ArgumentError] if service_class doesn't inherit from Idp::Service
      def register_idp_service(connector_id, service_class)
        initialize_registry
        raise ArgumentError, "#{service_class.name} must inherit from Idp::Service" unless service_class < Idp::Service

        @services[connector_id.to_s] = service_class
      end

      # Get an IDP service instance for the given connector_id.
      #
      # @param connector_id [String] The connector ID
      # @return [Idp::Service] Instance of the appropriate IDP service
      # @return [Idp::NullService] If connector_id is not registered
      def for_connector(connector_id)
        initialize_registry
        return Idp::NullService.new(connector_id) unless connector_id.present?

        service_class = @services[connector_id.to_s]
        return Idp::NullService.new(connector_id) unless service_class

        service_class.new
      end

      # Get list of supported connector IDs.
      #
      # @return [Array<String>] List of registered connector IDs
      def supported_idps
        initialize_registry
        @services.keys
      end

      # Check if an IDP supports a specific feature.
      #
      # @param connector_id [String] The connector ID
      # @param feature [Symbol] Feature to check (:user_management, :profile_updates)
      # @return [Boolean] true if IDP supports the feature
      def idp_supports_feature?(connector_id, feature)
        service = for_connector(connector_id)
        case feature
        when :user_management
          service.supports_user_management?
        when :profile_updates
          service.supports_profile_updates?
        else
          false
        end
      end
    end
  end
end
