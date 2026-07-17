###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# accessor API for CE configuration
module Hmis::Ce
  class Configuration
    # feature flag for CE
    def enabled?
      !!value_for(:enabled)
    end

    def bulk_void_enabled?
      !!value_for(:bulk_void_enabled)
    end

    protected

    # read all configuration values from the db
    PROPERTIES = [
      :enabled,
      :bulk_void_enabled,
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
      "hmis_ce/#{attr}"
    end
  end
end
