# frozen_string_literal: true

###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'aws-sdk-cloudwatch'

module GrdaWarehouse
  module DbMonitor
    # Checks the warehouse RDS instance's FreeStorageSpace via CloudWatch
    class FreeStorageSpace
      BYTES_PER_GB = 1_073_741_824.0

      def self.call(...) = new.call(...)

      def call(instance_id)
        cw = Aws::CloudWatch::Client.new
        now = Time.current
        resp = cw.get_metric_statistics(
          namespace: 'AWS/RDS',
          metric_name: 'FreeStorageSpace',
          dimensions: [{ name: 'DBInstanceIdentifier', value: instance_id }],
          start_time: now - 10.minutes.ago,
          end_time: now,
          period: 60,
          statistics: ['Minimum'],
          unit: 'Bytes',
        )

        if resp.datapoints.empty?
          Sentry.capture_message(
            'DbMonitor: no CloudWatch FreeStorageSpace datapoints returned -- monitor may be misconfigured',
            level: :warning,
            extra: { db_instance_identifier: instance_id },
          )
          return nil
        end

        # use the most recent reading
        minimum_bytes = resp.datapoints.max_by(&:timestamp).minimum
        minimum_bytes / BYTES_PER_GB
      end
    end
  end
end
