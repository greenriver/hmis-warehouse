# frozen_string_literal: true

###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  module DbMonitor
    class FreeStorageSpaceConfiguration
      # Alert (Sentry warning) when free space drops below this percentage of database size.
      # Returns nil when unconfigured.
      def alert_threshold_pct = value_for(:alert_threshold_pct)&.to_i

      # Block imports when free space drops below this percentage of database size.
      # Returns nil when unconfigured.
      def block_threshold_pct = value_for(:block_threshold_pct)&.to_i

      protected

      PROPERTIES = [
        :block_threshold_pct,
        :alert_threshold_pct,
      ].freeze
      def values
        @values ||= AppConfigProperty.
          where(key: PROPERTIES.map { |attr| key_for(attr) }).
          pluck(:key, :value).
          to_h
      end

      def value_for(attr)
        values[key_for(attr)]
      end

      def key_for(attr)
        "wh_db_space_monitor/#{attr}"
      end
    end
  end
end
