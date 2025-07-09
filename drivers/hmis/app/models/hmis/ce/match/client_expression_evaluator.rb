# frozen_string_literal: true

require 'dentaku'

module Hmis::Ce::Match
  class ClientExpressionEvaluator
    attr_reader :expression, :field_map

    def initialize(expression, field_map)
      @expression = expression
      @field_map = field_map
      @calculator = Hmis::Ce::Match::CalculatorFactory.build
    end

    def call(client)
      # construct client values for the expression.
      # Note, this isn't lazy so it's less performant that it could be
      client_values = @calculator.dependencies(expression).to_h do |field|
        [field, field_map.instance_value(client, field)]
      end

      # evaluate the expression, for example:
      # evaluate!('current_age >= 65 AND veteran_status = 1', {current_age: 50, veteran_status: 1})
      # => false
      @calculator.evaluate!(expression, **client_values)
    end
  end
end
