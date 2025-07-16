# frozen_string_literal: true

require 'dentaku'

module Hmis::Ce::Match
  class ClientExpressionEvaluator
    attr_reader :expression, :field_map

    Result = Struct.new(:client_values, :priority_score, : keyword_init: true)
    private_constant :Result

    def initialize(pool, field_map)
      @pool = pool

      @field_map = field_map
      @calculator = Hmis::Ce::Match::CalculatorFactory.build
      @dependencies = [
        @calculator.requirement_expression,
        @calculator.priority_expression,
      ].compact_blank.flat_map do |expression|
        @calculator.dependencies(expression)
      end.sort.uniq
    end

    def call(client)
      # construct client values for the expression.
      client_values = @dependencies.to_h do |field|
        [field, field_map.instance_value(client, field)]
      end

      # evaluate the pool's expressions, for example:
      # evaluate!('current_age >= 65 AND veteran_status = 1', {current_age: 50, veteran_status: 1})
      if @calculator.evaluate!(pool.requirement_expression, **client_values)
        priority_score = @calculator.evaluate!(pool.priority_expression, **client_values)
      end
      Result.new(
        client_values: client_values,
        priority_score: priority_score,
      )
    end
  end
end
