###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# accessor API for general HMIS configuration
module Hmis
  class Configuration
    # Feature flag for the ESG Funding Report, which intentionally exposes
    # services beyond a user's typical visibility. Off by default.
    def esg_funding_report_enabled?
      !!value_for(:esg_funding_report_enabled)
    end

    protected

    PROPERTIES = [
      :esg_funding_report_enabled,
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
      "hmis/#{attr}"
    end
  end
end
