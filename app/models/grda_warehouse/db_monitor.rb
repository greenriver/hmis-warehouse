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
      return unless config.block_threshold_pct || config.alert_threshold_pct

      instance_id = resolve_instance_id
      raise Error, 'DbMonitor: could not resolve warehouse RDS instance' unless instance_id

      free_gb = GrdaWarehouse::DbMonitor::FreeStorageSpace.call(instance_id)&.round(2)
      return unless free_gb

      db_size_gb = database_size_gb
      return unless db_size_gb

      if config.block_threshold_pct
        block_gb = (db_size_gb * config.block_threshold_pct / 100.0).round(2)
        if free_gb < block_gb
          raise Error, "DbMonitor: block threshold reached for #{instance_id} " \
                       "(#{free_gb} GB free, threshold #{block_gb} GB = #{config.block_threshold_pct}% of #{db_size_gb.round(2)} GB)"
        end
      end

      if config.alert_threshold_pct
        alert_gb = (db_size_gb * config.alert_threshold_pct / 100.0).round(2)
        if free_gb < alert_gb
          Sentry.capture_message(
            'DbMonitor: warehouse RDS instance is low on storage',
            level: :warning,
            extra: { free_storage_gb: free_gb, alert_threshold_gb: alert_gb, database_size_gb: db_size_gb.round(2) },
          )
        end
      end
    rescue Aws::Errors::ServiceError => e
      Sentry.capture_exception(e)
      Rails.logger.warn("DbMonitor: AWS error during health check: #{e.message}")
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
          endpoint = instance.endpoint&.address&.to_s
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
      bytes / FreeStorageSpace::BYTES_PER_GB
    rescue ActiveRecord::ActiveRecordError => e
      Sentry.capture_exception(e)
      Rails.logger.warn("DbMonitor: failed to query database size: #{e.message}")
      nil
    end
  end
end
