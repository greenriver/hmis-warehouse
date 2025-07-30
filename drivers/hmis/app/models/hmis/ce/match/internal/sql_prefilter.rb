# frozen_string_literal: true

module Hmis::Ce::Match::Internal
  # Responsible for translating a pool's `requirement_expression` into a SQL
  # `WHERE` clause to efficiently filter out non-matching clients at the
  # database level before performing more expensive in-memory evaluations.
  class SqlPrefilter
    Result = Struct.new(:eligible_clients, :lost_eligibility_clients, keyword_init: true)
    private_constant :Result

    def initialize(pool, field_map)
      @pool = pool
      @field_map = field_map
    end

    # note, the filter only works on candidates that are destination clients
    def call(client_universe)
      current_date = @field_map.respond_to?(:current_date) ? @field_map.current_date : Date.current
      calculator = Hmis::Ce::Match::Expression::CalculatorFactory.build(current_date: current_date)
      ast = calculator.ast(@pool.requirement_expression)
      translator = Hmis::Ce::Match::Expression::SqlExpressionTranslator.new(@field_map)
      translator.visit(ast)
      condition = translator.to_arel
      joins = translator.joins.compact

      return Result.new(eligible_clients: client_universe, lost_eligibility_clients: client_universe.none) unless condition

      # apply joins and filter the universe
      eligible_clients = client_universe.left_outer_joins(joins).where(condition)
      # find all clients that were in the pool but are no longer in the matching set
      current_clients_in_universe = @pool.warehouse_clients.where(id: client_universe.select(:id))
      lost_eligibility_clients = current_clients_in_universe.where.not(id: eligible_clients.select(:id))

      Result.new(
        eligible_clients: eligible_clients.distinct,
        lost_eligibility_clients: lost_eligibility_clients.distinct,
      )
    end
  end
end
