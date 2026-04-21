# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::CalculatedField
  # Resolves registry variables for a client (derived from enrollment), then evaluates
  # the CDED's Dentaku expression. Matches the CE pattern: stateless calculator + pre-loaded bindings.
  class Evaluator
    def initialize(enabled_resolvers: nil)
      @enabled_resolvers = enabled_resolvers
    end

    def evaluate(cded, enrollment:)
      return nil unless cded.calculated?

      client = enrollment.client
      variables = {}

      enabled_resolvers.each do |var_name, resolver_class|
        variables[var_name] = resolver_class.new.call(client)
      end

      calculator.evaluate!(cded.calculation_expression, **variables)
    end

    private

    def enabled_resolvers
      @enabled_resolvers ||= Registry.enabled
    end

    def calculator
      @calculator ||= CalculatorFactory.build
    end
  end
end
