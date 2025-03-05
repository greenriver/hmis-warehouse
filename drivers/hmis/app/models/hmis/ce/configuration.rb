###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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

    # If a candidate pool is no longer associated with any active opportunities, how long should it be retained?
    def days_to_retain_orphan_candidate_pools
      value_for(:days_to_retain_orphan_candidate_pools)&.to_i
    end

    protected

    # read all configuration values from the db
    PROPERTIES = [
      :enabled,
      :days_to_retain_orphan_candidate_pools,
    ].freeze
    def values
      @values ||= AppConfigProperty.
        where(key: PROPERTIES.map { |attr| key_for(attr) }).
        index_by(&:key)
    end

    def value_for(attr)
      values[key_for(attr)]
    end

    def key_for(attr)
      "hmis_ce/#{attr}"
    end
  end
end
