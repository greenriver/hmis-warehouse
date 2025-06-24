# frozen_string_literal: true

require 'dentaku'

module Hmis::Ce::Match
  module CalculatorFactory
    # calculator with custom functions
    def self.build
      calculator = Dentaku::Calculator.new
      calculator.add_function(
        :includes,
        :logical,
        ->(a, b) { Array(a).include?(b) },
      )
      calculator.add_function(
        :excludes,
        :logical,
        ->(a, b) { !Array(a).include?(b) },
      )

      return calculator
    end
  end
end
