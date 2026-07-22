###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::Ce::Match::Expression
  # FieldMap implementation for flat psde.* expression keys (e.g. psde.total_monthly_income).
  class PsdeFieldMap
    NAMESPACE = 'psde'

    def initialize(current_date: Date.current, configuration: Hmis::Ce.configuration)
      @current_date = current_date
      @configuration = configuration
    end

    def client_query(clients, field)
      psde_field = PsdeFieldRegistry[field]
      raise ArgumentError, "Unknown PSDE field \"#{field}\"" unless psde_field

      value_resolver.call(clients, psde_field)
    end

    def joins(_field)
      nil
    end

    def arel_field(_field)
      nil
    end

    def fields
      PsdeFieldRegistry::ALL
    end

    def label_for(field)
      PsdeFieldRegistry[field]&.label || field.to_s.humanize
    end

    def format_for_display(_field, value)
      value
    end

    def self.field_key_for(field_key)
      "#{NAMESPACE}.#{field_key}"
    end

    private

    def value_resolver
      @value_resolver ||= PsdeValueResolver.new(
        current_date: @current_date,
        configuration: @configuration,
      )
    end
  end
end
