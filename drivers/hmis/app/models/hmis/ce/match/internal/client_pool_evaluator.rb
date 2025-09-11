# frozen_string_literal: true

require 'dentaku'

module Hmis::Ce::Match::Internal
  # This class evaluates a batch of clients against a candidate pool's criteria.
  # To prevent N+1 queries, it pre-fetches all required field dependencies for the entire
  # client collection upon initialization. The `call` method then uses this in-memory
  # cache for fast, individual client evaluation.
  class ClientPoolEvaluator
    attr_reader :expression, :field_map

    # simple evaluation result object
    Result = Struct.new(:client_values, :priority_scores) do
      # Determines if the client evaluation failed based on priority scores.
      #
      # Client is ineligible for Pool if:
      # - Priority scores are nil or empty. This indicates that prioritization never ran, because client was ineligible. Or,
      # - Any value in the priority scores array is nil. NOTE: To include clients with missing prioritization values,
      #   use a coalescing priority expression such as `IF(my_score = NULL, 0, my_score)`
      def failed?
        priority_scores.nil? || priority_scores.empty? || priority_scores.any?(&:nil?)
      end
    end
    private_constant :Result

    def initialize(clients, pool, field_map)
      @pool = pool

      @field_map = field_map
      @calculator = Hmis::Ce::Match::Expression::CalculatorFactory.build
      @dependencies = [
        pool.requirement_expression,
        pool.priority_expression,
      ].compact_blank.flat_map do |expression|
        @calculator.dependencies(expression)
      end.sort.uniq

      @client_field_values = {}
      @dependencies.each do |field|
        field_map.client_query(clients, field).each do |client_id, value|
          @client_field_values[client_id] ||= {}
          @client_field_values[client_id][field] = value
        end
      end
    end

    # @param client [GrdaWarehouse::Hud::Client] The client to evaluate
    # @param field_value_overrides [Hash] Optional field value overrides, used for calculating eligibility
    #   based on form state before the assessment is submitted.
    # @return [Result] Contains client values used in evaluation and priority scores (if eligible)
    def call(client, field_value_overrides: {})
      client_values = @client_field_values[client.id] || {}
      client_values = client_values.merge(field_value_overrides)

      # Only run priority evaluation if eligibility evaluation passed.
      # To be eligible, client's priority scores must all be non-null AND the eligibility requirement must pass.
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
      @calculator.evaluate!(@pool.priority_expression, **client_values)
    end
  end
end
