###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# accessor API for general HMIS configuration
module HmisExternalApis::AcHmis
  class Configuration
    ALT_AHA_MODEL_VERSIONS = [1, 2].freeze

    # Feature flag for the ESG Funding Report, which intentionally exposes
    # services beyond a user's typical visibility. Off by default.
    def esg_funding_report_enabled?
      value_for(:esg_funding_report_enabled) == true
    end

    # Which Alt-AHA scoring model this environment uses, matched against
    # Hmis::Scoring::Rule#model_version. Unset means 1. Accepts the integer or its
    # string form, and raises on anything else rather than falling back to 1.
    def alt_aha_model_version
      value = value_for(:alt_aha_model_version)
      return 1 if value.nil?

      version = ALT_AHA_MODEL_VERSIONS.find { |v| value.to_s == v.to_s }
      raise ArgumentError, "Invalid #{key_for(:alt_aha_model_version)}: #{value.inspect}" unless version

      version
    end

    protected

    PROPERTIES = [
      :esg_funding_report_enabled,
      :alt_aha_model_version,
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
      "ac_hmis/#{attr}"
    end
  end
end
