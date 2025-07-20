# frozen_string_literal: true

require 'dentaku'

module Hmis::Ce::Match::Internal
  class ClientPoolEvaluator
    attr_reader :expression, :field_map

    Result = Struct.new(:client_values, :priority_score)
    private_constant :Result

    def initialize(pool, field_map)
      @pool = pool

      @field_map = field_map
      @calculator = Hmis::Ce::Match::Expression::CalculatorFactory.build
      @dependencies = [
        pool.requirement_expression,
        pool.priority_expression,
      ].compact_blank.flat_map do |expression|
        @calculator.dependencies(expression)
      end.sort.uniq
    end

    def call(client)
      # construct client values for the expression.
      client_values = @dependencies.to_h do |field|
        [field, field_map.instance_value(client, field)]
      end

      # both priority and eligibility must be true to match.
      priority = eval_priority(client_values) if eval_requirement(client_values)
      Result.new(client_values, priority)
    end

    protected

    # evaluate the pool's expressions, for example:
    # evaluate!('current_age >= 65 AND veteran_status = 1', {current_age: 50, veteran_status: 1})
    def eval_requirement(client_values)
      @calculator.evaluate!(@pool.requirement_expression, **client_values)
    end

    def eval_priority(client_values)
      @calculator.evaluate!(@pool.priority_expression, **client_values)
    end
  end
end
