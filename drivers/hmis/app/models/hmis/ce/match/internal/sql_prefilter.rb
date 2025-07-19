# frozen_string_literal: true

module Hmis::Ce::Match::Internal
  # Responsible for translating a pool's `requirement_expression` into a SQL
  # `WHERE` clause to efficiently filter out non-matching clients at the
  # database level before performing more expensive in-memory evaluations.
  class SqlPrefilter
    Result = Struct.new(:matching_clients, :removed_clients, keyword_init: true)
    private_constant :Result

    def initialize(pool, field_map)
      @pool = pool
      @field_map = field_map
    end

    # note, the filter only works on candidates that are destination clients
    def call(client_universe)
      condition = Hmis::Ce::Match::Expression::SqlExpressionTranslator.call(@pool.requirement_expression, @field_map)
      return Result.new(matching_clients: client_universe.none, removed_clients: client_universe.none) unless condition

      # filter the universe
      matching_clients = client_universe.where(condition)
      # find all clients that were in the pool but are no longer in the matching set
      current_clients_in_universe = @pool.warehouse_clients.where(id: client_universe)
      removed_clients = current_clients_in_universe.where.not(id: matching_clients.select(:id))

      Result.new(
        matching_clients: matching_clients,
        removed_clients: removed_clients,
      )
    end
  end
end
