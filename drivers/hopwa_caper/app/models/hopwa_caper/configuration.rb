# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HopwaCaper
  class Configuration
    # Feature flag for the ATC tab
    def atc_tab_enabled?
      !!value_for(:atc_tab_enabled)
    end

    # Custom field names/identifiers for ATC questions
    # These should map to a way to identify the custom data element or assessment question
    def atc_maintained_contact_field_name
      value_for(:atc_maintained_contact_field_name)
    end

    def atc_housing_plan_field_name
      value_for(:atc_housing_plan_field_name)
    end

    def atc_primary_health_contact_field_name
      value_for(:atc_primary_health_contact_field_name)
    end

    protected

    PROPERTIES = [
      :atc_tab_enabled,
      :atc_maintained_contact_field_name,
      :atc_housing_plan_field_name,
      :atc_primary_health_contact_field_name,
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
      "hopwa_caper/#{attr}"
    end
  end
end
