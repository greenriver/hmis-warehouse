###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Idp
  # Registry of Idp::Service implementations by provider, and resolver from a
  # connector_id to a configured service (see #for_connector).
  class ServiceFactory
    class << self
      def services
        @services ||= {}
      end

      # Register an IDP service class for a provider (IDP type, e.g. 'keycloak').
      # @raise [ArgumentError] unless service_class inherits from Idp::Service
      def register_idp_service(provider, service_class)
        raise ArgumentError, "#{service_class.name} must inherit from Idp::Service" unless service_class < Idp::Service

        services[provider.to_s] = service_class
      end

      # Resolve a connector_id (the auth-proxy routing key) to its service. The active
      # Idp::ServiceConfig row is the single source of truth; there is no ENV fallback.
      #
      # Degrades to a NullService instead of raising: a valid token from a connector with no active
      # config must still pass the capability checks in Idp::Support#idp_service without crashing the
      # request (authentication itself works off the JWT alone, never this method).
      def for_connector(connector_id)
        return Idp::NullService.new(connector_id) unless connector_id.present?

        active_config = Idp::ServiceConfig.active.find_by(connector_id: connector_id)
        active_config ? active_config.to_service : Idp::NullService.new(connector_id)
      end

      # @return [Array<String>] registered provider keys (IDP types)
      def supported_providers
        services.keys
      end

      # How recent a user's activity must be to count as "recently active". Note
      # this is not a session timeout — those are handled by JWT expiration.
      def recent_activity_period
        30.minutes
      end
    end
  end
end
