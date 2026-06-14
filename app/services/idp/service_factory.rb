###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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
      # Registry mapping provider (IDP type) to service class.
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
      # @raise [Idp::ServiceError] when no config exists and connector_id isn't a known provider
      def for_connector(connector_id)
        return Idp::NullService.new(connector_id) unless connector_id.present?

        # Prefer DB-managed credentials. Guarded so the factory is usable before
        # the idp_service_configs table exists (e.g. during its own migration).
        config_record = Idp::ServiceConfig.active.find_by(connector_id: connector_id) if defined?(Idp::ServiceConfig)
        return config_record.to_service if config_record

        # No managed config: treat connector_id as a provider key for ENV defaults.
        service_class = services[connector_id.to_s]
        raise Idp::ServiceError.new("No IDP config for connector: #{connector_id}", operation: :for_connector) unless service_class

        service_class.new
      end

      # @return [Array<String>] registered provider keys (IDP types)
      def supported_providers
        services.keys
      end

      # @param feature [Symbol] :user_management or :profile_updates
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
      rescue Idp::ServiceError
        false
      end

      # Window used to determine recent user activity (consumed by L4.1).
      # Session timeout is handled by JWT expiration, not by this value.
      def recent_activity_period
        30.minutes
      end
    end
  end
end
