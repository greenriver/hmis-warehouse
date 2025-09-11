# frozen_string_literal: true

require 'dentaku'

module Hmis::Ce::Match::Expression
  module CalculatorFactory
    # calculator with custom functions
    def self.build
      calculator = Dentaku::Calculator.new(case_sensitive: true) # CDED keys are case sensitive, so Dentaku expressions should be too
      calculator.add_function(
        :INCLUDES,
        :logical,
        ->(a, b) do
          return false if a.nil? || b.nil?

          Array(a).include?(b)
        end,
      )
      calculator.add_function(
        :EXCLUDES,
        :logical,
        ->(a, b) do
          return false if a.nil? || b.nil?

          !Array(a).include?(b)
        end,
      )
      calculator.add_function(
        :PROJECT_TYPE,
        :string,
        ->(identifier) do
          return nil if identifier.nil?

          HudUtilityCurrent.hmis_project_type_key(identifier, true)
        end,
      )
      calculator.add_function(
        :EPOCH_SECONDS,
        :numeric,
        ->(value) {
          return nil if value.nil?

          case value
          when ActiveSupport::TimeWithZone, Time
            value.in_time_zone.to_i
          when Date
            Time.zone.local(value.year, value.month, value.day).to_i
          when String
            parsed = Time.zone.parse(value)
            raise ArgumentError, "Cannot cast #{value.inspect} to seconds" unless parsed

            parsed.to_i
          else
            raise ArgumentError, "Cannot cast #{value.inspect} to seconds"
          end
        },
      )

      return calculator
    end
  end
end
