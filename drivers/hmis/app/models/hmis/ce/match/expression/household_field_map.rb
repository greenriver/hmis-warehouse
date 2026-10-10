###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::Ce::Match::Expression
  # FieldMap implementation for household.* expression keys (e.g. household.size).
  class HouseholdFieldMap
    def initialize(current_date: Date.current, configuration: Hmis::Ce.configuration)
      @current_date = current_date
      @configuration = configuration
    end

    def client_query(clients, field)
      household_field = HouseholdFieldRegistry[field]
      raise ArgumentError, "Unknown household field \"#{field}\"" unless household_field

      value_resolver.call(clients, household_field)
    end

    def joins(_field)
      nil
    end

    # No SQL prefilter support; household fields are evaluated in Ruby
    def arel_field(_field)
      nil
    end

    def fields
      HouseholdFieldRegistry::ALL
    end

    def label_for(field)
      HouseholdFieldRegistry[field]&.label || field.to_s.humanize
    end

    def format_for_display(_field, value)
      value&.to_s
    end

    private

    def value_resolver
      @value_resolver ||= HouseholdValueResolver.new(
        current_date: @current_date,
        configuration: @configuration,
      )
    end
  end
end
