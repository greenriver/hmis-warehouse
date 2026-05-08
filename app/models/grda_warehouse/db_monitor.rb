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
      raise Error, 'DbMonitor: could not resolve warehouse RDS instance' unless instance_id

      free_gb = GrdaWarehouse::DbMonitor::FreeStorageSpace.call(instance_id)&.round(2)
      return unless free_gb

      if free_gb < config.block_threshold_gb
        raise Error, "DbMonitor: block threshold reached for #{instance_id} (#{free_gb} GB free)"
      elsif free_gb < config.alert_threshold_gb
        Sentry.capture_message('DbMonitor: warehouse RDS instance is low on storage', level: :warning, extra: { free_storage_gb: free_gb })
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
  end
end
