# frozen_string_literal: true

require 'progress_bar'

# The Coordinated Entry (CE) Match Engine is responsible for evaluating a universe of clients
# against a set of eligibility and prioritization rules for a given candidate pool.
# It identifies which clients are eligible for the pool and calculates a priority score for each.
# The engine is designed to be idempotent and can be run repeatedly without causing side effects.
#
# See README_FOR_CE_MATCH_ENGINE.md
module Hmis::Ce::Match
  # Orchestrates the process of evaluating a universe of clients against a
  # candidate pool's criteria. It coordinates various components to filter,
  # evaluate, and persist candidates and their corresponding events.
  class Engine
    # Convenience class method to instantiate and call the engine in one step.
    def self.call(pool, clients: nil, progress: false)
      new(pool).call(clients, progress: progress)
    end

    def initialize(pool)
      @pool = pool
      @field_map = Hmis::Ce::Match::Expression::FieldMap.new
      @evaluator = Hmis::Ce::Match::Internal::ClientPoolEvaluator.new(@pool, @field_map)
      @event_writer = Hmis::Ce::Match::Internal::CandidateEventWriter.new(@pool)
      @repo = Hmis::Ce::Match::Internal::CandidateRepository.new(@pool)
      @prefilter = Hmis::Ce::Match::Internal::SqlPrefilter.new(@pool, @field_map)
    end

    def call(clients, progress: false)
      if clients.nil?
        # Full refresh - process all clients and remove all unmatched candidates
        clients = ::GrdaWarehouse::Hud::Client.destination
        incremental = false
      else
        # Incremental - process only provided clients and remove candidates only for those clients
        incremental = true
        validate_clients_parameter!(clients)
      end

      # optionally track the in-memory evaluations, which is the expensive work
      progress_bar = nil
      if progress
        progress_bar = new_progress_bar
        progress_bar.max += clients.count
      end

      # SQL Prefiltering
      prefilter_result = @prefilter.call(clients)
      # capture snapshots at time of removal for the event log
      removed_client_snapshots = generate_snapshots(prefilter_result.lost_eligibility_clients, progress_bar)

      started_at = Time.current
      prefilter_result.eligible_clients.in_batches do |batch|
        now = Time.current
        # import missing Client Proxies
        @repo.import_proxies(batch, timestamp: now)
        # efficient lookup for client_id => proxy_id
        warehouse_proxy_id_map = @repo.proxy_ids_by_warehouse_client(batch)
        # track which clients in this batch are currently matched to the pool
        current_warehouse_clients_ids = @repo.current_warehouse_client_ids(batch)

        # Perform In-Memory Evaluation on each client
        matching_candidates = []
        matching_client_snapshots = []
        batch.each do |client|
          progress_bar&.increment!
          evaluation = @evaluator.call(client)

          # Client without a score cannot be prioritized, so do not include them in the pool.
          # If needing to include clients that don't have a score, expression should be set up like `IF(my_score = NULL, 0, my_score)`
          if evaluation.priority_score.nil?
            removed_client_snapshots.push([client.id, evaluation.client_values]) if client.id.in?(current_warehouse_clients_ids)
            next
          end

          matching_candidates << {
            candidate_pool_id: @pool.id,
            client_proxy_id: warehouse_proxy_id_map.fetch(client.id),
            priority_score: evaluation.priority_score,
            created_at: now,
            updated_at: now,
          }
          matching_client_snapshots.push([client.id, evaluation.client_values])
        end

        @repo.import_candidates(matching_candidates)
        # Event Logging
        @event_writer.call(matching_client_snapshots, timestamp: now)
      end

      # Remove old candidates that no longer match
      if incremental
        # In incremental mode, only remove candidates for clients that were in the input scope
        # This ensures we remove candidates for clients who no longer pass any filters
        @repo.remove_stale_candidates(client_ids: clients.pluck(:id), updated_before: started_at)
      else
        # In full mode, remove all candidates that were not updated during this run
        @repo.remove_all_stale_candidates(updated_before: started_at)
      end

      # Event Logging
      @event_writer.call(removed_client_snapshots, timestamp: started_at)
      @pool.update!(candidates_generated_at: started_at)
    end

    private

    def validate_clients_parameter!(clients)
      raise ArgumentError, "clients must be an ActiveRecord relation, got #{clients.class.name}" unless clients.is_a?(ActiveRecord::Relation) && clients.klass == GrdaWarehouse::Hud::Client
    end

    def generate_snapshots(clients, progress_bar)
      snapshots = []
      return snapshots if clients.none?

      progress_bar.max += clients.count if progress_bar
      clients.find_each do |client|
        snapshots.push([client.id, @evaluator.call(client).client_values])
        progress_bar&.increment!
      end
      snapshots
    end
  end

  def new_progress_bar
    puts "Processing pool[#{@pool.id}] eligibility: #{@pool.requirement_expression.inspect}, priority: #{@pool.priority_expression.inspect}"
    ProgressBar.new(0, :counter, :bar, :percentage, :rate, :eta)
  end
end
