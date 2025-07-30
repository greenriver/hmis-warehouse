# frozen_string_literal: true

require 'dentaku'

module Hmis::Ce::Match::Expression
  module CalculatorFactory
    # calculator with custom functions
    def self.build(current_date: Date.current)
      calculator = Dentaku::Calculator.new(case_sensitive: true) # CDED keys are case sensitive, so Dentaku expressions should be too
      calculator.add_function(
        :INCLUDES,
        :logical,
        ->(a, b) { Array(a).include?(b) },
      )
      calculator.add_function(
        :EXCLUDES,
        :logical,
        ->(a, b) { !Array(a).include?(b) },
      )
      calculator.add_function(
        :PROJECT_TYPE,
        :string,
        ->(identifier) { HudUtility2026.hmis_project_type_key(identifier, true) },
      )
      calculator.add_function(
        :DAYS_AGO,
        :numeric,
        ->(date) {
          # Handle various date formats and nil values
          return nil if date.nil?

          parsed_date = case date
          when Date
            date
          when String
            Date.parse(date)
          else
            raise TypeError, "Expected Date or String, got #{date.class}"
          end

          (current_date - parsed_date).to_i
        },
      )

      return calculator
    end
  end
end
