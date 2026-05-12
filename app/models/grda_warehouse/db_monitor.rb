# frozen_string_literal: true

###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'aws-sdk-rds'

module GrdaWarehouse
  # Pre-flight health check for the warehouse RDS instance. Called before
  # db-intensive operations (imports, bulk deletes) to avoid exhausting disk
  # space. Fail-open: AWS errors degrade to Sentry warnings, never block work.
  module DbMonitor
    class Error < StandardError; end
    RdsInstance = Data.define(:id, :allocated_storage_gb, :free_storage_gb)

    def self.assert_healthy!
      config = FreeStorageSpaceConfiguration.new
      return unless config.enabled?

      instance = resolve_instance
      return capture_warning('could not resolve warehouse RDS instance') if instance.nil?
      return capture_warning("unable to retrieve free storage space for #{instance.id}") if instance.free_storage_gb.nil?

      free_gb = instance.free_storage_gb
      allocated_gb = instance.allocated_storage_gb

      if config.block_threshold_pct
        block_gb = (allocated_gb * config.block_threshold_pct / 100.0).round(2)
        block_gb = block_gb.clamp(config.min_block_threshold_gb, config.max_block_threshold_gb)
        if free_gb < block_gb
          raise Error, "DbMonitor: block threshold reached for #{instance.id} " \
                       "(#{free_gb} GB free, threshold #{block_gb} GB = #{config.block_threshold_pct}% of #{allocated_gb} GB allocated)"
        end
      end

      return unless config.alert_threshold_pct

      alert_gb = (allocated_gb * config.alert_threshold_pct / 100.0).round(2)
      return unless free_gb < alert_gb

      capture_warning(
        'warehouse RDS instance is low on storage',
        extra: { free_storage_gb: free_gb, alert_threshold_gb: alert_gb, allocated_storage_gb: allocated_gb },
      )
    rescue Aws::Errors::ServiceError => e
      capture_warning("AWS error during health check: #{e.message}")
    end

    def self.capture_warning(message, extra: nil)
      Sentry.capture_message("DbMonitor: #{message}", level: :warning, extra: extra)
      nil
    end

    # Iterates all RDS instances to find one whose endpoint address matches
    # WAREHOUSE_DATABASE_HOST. RDS hostnames are of the form
    # <identifier>.xxxxxxxx.<region>.rds.amazonaws.com, so we match on the
    # leading segment rather than an exact hostname comparison in case the env
    # var is set to a CNAME or partial hostname.
    def self.resolve_instance
      warehouse_host = ENV.fetch('WAREHOUSE_DATABASE_HOST', nil)
      return nil unless warehouse_host.present?

      rds = Aws::RDS::Client.new
      rds.describe_db_instances.each do |page|
        page.db_instances.each do |instance|
          endpoint = instance.endpoint&.address.to_s
          next unless endpoint == warehouse_host || endpoint.start_with?("#{warehouse_host}.")

          free_gb = FreeStorageSpace.call(instance.db_instance_identifier)&.round(2)
          return RdsInstance.new(
            id: instance.db_instance_identifier,
            allocated_storage_gb: instance.allocated_storage,
            free_storage_gb: free_gb,
          )
        end
      end

      nil
    end
  end
end
