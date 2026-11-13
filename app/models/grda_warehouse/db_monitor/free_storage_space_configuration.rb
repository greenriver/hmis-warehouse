###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  module DbMonitor
    class FreeStorageSpaceConfiguration
      def enabled? = alert_threshold_pct.present? || block_threshold_pct.present?

      # Alert (Sentry warning) when free space drops below this percentage of database size.
      # Returns nil when unconfigured.
      def alert_threshold_pct = value_for(:alert_threshold_pct)&.to_i

      # Block imports when free space drops below this percentage of database size.
      # Returns nil when unconfigured.
      def block_threshold_pct = value_for(:block_threshold_pct)&.to_i

      # Regardless of database size, constrain the block threshold to absolute GB
      def min_block_threshold_gb = value_for(:min_block_threshold_gb)&.to_i || 1
      def max_block_threshold_gb = value_for(:max_block_threshold_gb)&.to_i || 100

      protected

      PROPERTIES = [
        :block_threshold_pct,
        :min_block_threshold_gb,
        :max_block_threshold_gb,
        :alert_threshold_pct,
      ].freeze
      def values
        @values ||= AppConfigProperty.
          where(key: PROPERTIES.map { |attr| key_for(attr) }).
          pluck(:key, :value).
          to_h
      end

      def value_for(attr)
        values[key_for(attr)].presence
      end

      def key_for(attr)
        "wh_db_space_monitor/#{attr}"
      end
    end
  end
end
