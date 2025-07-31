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

      return calculator
    end
  end
end
