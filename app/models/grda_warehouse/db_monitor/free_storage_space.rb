###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'aws-sdk-cloudwatch'

module GrdaWarehouse
  module DbMonitor
    # Returns the median free storage (GB) over the last 10 minutes. Using the
    # median filters out transient spikes without masking a genuine shortage.
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
          start_time: now - 10.minutes,
          end_time: now,
          period: 60,
          statistics: ['Average'],
          unit: 'Bytes',
        )

        return nil if resp.datapoints.empty?

        values = resp.datapoints.filter_map(&:average).sort
        return nil if values.empty?

        median_bytes = values[(values.size - 1) / 2]
        median_bytes / BYTES_PER_GB
      end
    end
  end
end
