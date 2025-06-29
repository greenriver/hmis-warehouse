# frozen_string_literal: true

# * Find all clients that match the given pools's eligibility requirements.
# * Score each client based on that pools's prioritization formula.
# * Persist the results as MatchCandidate records to be consumed by opportunities.
#
module Hmis::Ce::Match
  class Engine
    def self.call(...)
      new.call(...)
    end

    # Take a two-step approach to evaluating eligibility to achieve better performance.
    # 1. Translate the eligibility requirements expression into a SQL condition and filter the clients. Uses field_map.arel_node to achieve this translation. Expression components that cannot be represented in SQL are treated as truthy. This reduces the number of client records that we need to evaluate in the more expensive second step.
    # 2. Evaluate the eligibility requirement expression against each matched client. We expect all expression variables to be defined.
    def call(pool, clients)
      validate_clients_parameter!(clients)
      # TODO: remove this in #7671
      clients = translate_source_to_destination_scope(clients)

      eligibility_evaluator = ClientExpressionEvaluator.new(pool.requirement_expression, field_map)
      priority_evaluator = ClientExpressionEvaluator.new(pool.priority_expression, field_map)

      now = DateTime.current
      crude_eligibility_filter(pool.requirement_expression, clients).in_batches do |batch|
        matches = []
        batch.each do |client|
          # note, we could also set an expiration date on the candidate to allow us to skip records we have evaluated recently
          next unless eligibility_evaluator.call(client)

          score = priority_evaluator.call(client)
          matches << {
            candidate_pool_id: pool.id,
            client_id: client.id,
            priority_score: score,
            created_at: now,
            updated_at: now,
          }
        end
        import_candidates!(matches)
      end
      # remove old candidates that no longer match
      pool.candidates.where(updated_at: ...now).delete_all
      pool.update!(candidates_generated_at: Time.current)
    end

    protected

    # TODO: remove this in #7671
    # Resolve as a GrdaWarehouse destination client. Hmis::Hud::Client model isn't meant to be used with Destination clients
    def translate_source_to_destination_scope(clients)
      GrdaWarehouse::Hud::Client.joins(:warehouse_client_destination).
        where(warehouse_clients: { source_id: clients.select(:id) })
    end

    def validate_clients_parameter!(clients)
      raise ArgumentError, "clients must be an ActiveRecord relation, got #{clients.class.name}" unless clients.is_a?(ActiveRecord::Relation) && clients.klass == Hmis::Hud::Client
    end

    def import_candidates!(values)
      result = Candidate.import(
        values, on_duplicate_key_update: {
          conflict_target: [:candidate_pool_id, :client_id],
          columns: [:priority_score, :updated_at],
        }
      )
      raise "failed to import Candidates: #{result.inspect}" if result.failed_instances.present?
    end

    def crude_eligibility_filter(expression, clients)
      condition = SqlExpressionTranslator.call(expression, field_map)
      condition ? clients.where(condition) : clients
    end

    def field_map
      @field_map ||= FieldMap.new
    end
  end
end
