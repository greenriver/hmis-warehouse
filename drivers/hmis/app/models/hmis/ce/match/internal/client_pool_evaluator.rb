# frozen_string_literal: true

require 'dentaku'

module Hmis::Ce::Match::Internal
  class ClientPoolEvaluator
    attr_reader :expression, :field_map

    # simple evaluation result object
    Result = Struct.new(:client_values, :priority_scores) do
      # no priority_scores indicates the client is not eligible for the pool
      def failed? = priority_scores.nil? || priority_scores.empty?
    end
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

      # Client without a score cannot be prioritized
      #   * To be eligible priority score must be non-empty AND the eligibility requirement must pass
      #   * To include clients with empty scores, use a coalescing priority expression such as
      #     `IF(my_score = NULL, 0, my_score)`
      priority_scores = eval_priority(client_values) if eval_requirement(client_values)
      Result.new(client_values, priority_scores)
    end

    protected

    # evaluate the pool's expressions, for example:
    # evaluate!('current_age >= 65 AND veteran_status = 1', {current_age: 50, veteran_status: 1})
    def eval_requirement(client_values)
      @calculator.evaluate!(@pool.requirement_expression, **client_values)
    end

    def eval_priority(client_values)
      priority_expressions = @pool.priority_expression.split('|||')
      priority_expressions.map do |expression|
        @calculator.evaluate!(expression, **client_values)
      end
    end
  end
end
