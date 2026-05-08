# frozen_string_literal: true

###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  module DbMonitor
    class FreeStorageSpaceConfiguration
      def enabled?
        !!ActiveModel::Type::Boolean.new.cast(value_for(:enabled))
      end

      # Alert (Sentry warning) when free space drops below this threshold
      def alert_threshold_gb = value_for(:alert_threshold_gb)&.to_i || 20

      # Block imports when free space drops below this threshold
      def block_threshold_gb = value_for(:block_threshold_gb)&.to_i || 10

      protected

      # read all configuration values from the db
      PROPERTIES = [
        :enabled,
        :block_threshold_gb,
        :alert_threshold_gb,
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
