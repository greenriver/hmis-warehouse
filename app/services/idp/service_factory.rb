###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Idp
  # Registry mapping a connector_id to its Idp::Service implementation.
  #
  # for_connector is fail-soft: a blank connector returns a NullService, and a
  # DB-backed Idp::ServiceConfig is preferred over a registered class so ops can
  # manage credentials in the UI. Only a registered-but-unknown id raises.
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

      # Get an IDP service instance for the given connector_id (the auth-proxy
      # routing key). Prefers an active Idp::ServiceConfig record; with no config,
      # falls back to a registered service class — which only resolves when the
      # connector_id happens to equal a provider key (the single-realm/ENV path).
      #
      # Fail-soft: an unknown connector returns a NullService rather than raising.
      # Authentication never consults this method (UserProvisioner works off the
      # JWT alone), so a valid token from a connector with no config must still
      # degrade to "no management" on capability checks instead of crashing the
      # request — see Idp::Support#idp_service.
      def for_connector(connector_id)
        return Idp::NullService.new(connector_id) unless connector_id.present?

        # Prefer DB-managed credentials. Guarded so the factory is usable before
        # the idp_service_configs table exists (e.g. during its own migration).
        config_record = Idp::ServiceConfig.active.find_by(connector_id: connector_id) if defined?(Idp::ServiceConfig)
        return config_record.to_service if config_record

        # No managed config: treat connector_id as a provider key for ENV defaults.
        service_class = services[connector_id.to_s]
        return service_class.new if service_class

        # Unknown connector: authenticated but unconfigured. Degrade gracefully.
        Idp::NullService.new(connector_id)
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
