# frozen_string_literal: true

###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'aws-sdk-rds'

module GrdaWarehouse
  module DbMonitor
    class Error < StandardError; end

    def self.assert_healthy!
      config = FreeStorageSpaceConfiguration.new
      return unless config.enabled?

      instance_id = resolve_instance_id
      return capture_warning('could not resolve warehouse RDS instance') if instance_id.nil?

      free_gb = GrdaWarehouse::DbMonitor::FreeStorageSpace.call(instance_id)&.round(2)
      return capture_warning("unable to retrieve free storage space for #{instance_id}") if free_gb.nil?

      db_size_gb = database_size_gb
      return capture_warning("unable to determine warehouse database size") if db_size_gb.nil?

      if config.block_threshold_pct
        block_gb = (db_size_gb * config.block_threshold_pct / 100.0).round(2)
        block_gb = block_gb.clamp(config.min_block_threshold_gb, config.max_block_threshold_gb)
        if free_gb < block_gb
          raise Error, "DbMonitor: block threshold reached for #{instance_id} " \
                       "(#{free_gb} GB free, threshold #{block_gb} GB = #{config.block_threshold_pct}% of #{db_size_gb.round(2)} GB)"
        end
      end

      return unless config.alert_threshold_pct

      alert_gb = (db_size_gb * config.alert_threshold_pct / 100.0).round(2)
      return unless free_gb < alert_gb

      capture_warning(
        'warehouse RDS instance is low on storage',
        extra: { free_storage_gb: free_gb, alert_threshold_gb: alert_gb, database_size_gb: db_size_gb.round(2) },
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
    def self.resolve_instance_id
      warehouse_host = ENV.fetch('WAREHOUSE_DATABASE_HOST', nil)
      return nil unless warehouse_host.present?

      rds = Aws::RDS::Client.new
      rds.describe_db_instances.each do |page|
        page.db_instances.each do |instance|
          endpoint = instance.endpoint&.address.to_s
          return instance.db_instance_identifier if endpoint == warehouse_host || endpoint.start_with?("#{warehouse_host}.")
        end
      end

      nil
    end

    # Returns the warehouse database size in GB via pg_database_size().
    # Used as a scaling factor so thresholds grow with the database,
    # staying safely below the RDS autoscaling trigger.
    def self.database_size_gb
      bytes = GrdaWarehouseBase.connection.select_value('SELECT pg_database_size(current_database())')
      return nil unless bytes

      bytes / FreeStorageSpace::BYTES_PER_GB
    end
  end
end
