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

    def format_for_display(field, value)
      return value if value.nil? || value.empty?

      psde_field = PsdeFieldRegistry[field]
      return value unless psde_field

      value_type = psde_field.value_type
      multiple = psde_field.multiple

      return _format_for_display(value_type, value) unless multiple

      Array.wrap(value).map { |v| _format_for_display(value_type, v) }
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

    def _format_for_display(value_type, value)
      case value_type
      when :logical
        value ? 'Yes' : 'No'
      else
        value.to_s # could expand this later if there are dates or other types
      end
    end
  end
end
