# frozen_string_literal: true

require 'progress_bar'

# The Coordinated Entry (CE) Match Engine is responsible for evaluating a universe of clients
# against a set of eligibility and prioritization rules for a given candidate pool.
# It identifies which clients are eligible for the pool and calculates a priority score for each.
# The engine is designed to be idempotent and can be run repeatedly without causing side effects.
#
# See drivers/hmis/app/models/hmis/ce/match/README_FOR_CE_MATCH_ENGINE.md
module Hmis::Ce::Match
  # Orchestrates the process of evaluating a universe of clients against a
  # candidate pool's criteria. It coordinates various components to filter,
  # evaluate, and persist candidates and their corresponding events.
  class Engine
    # Convenience class method to instantiate and call the engine in one step.
    def self.call(pool, clients:, progress: false)
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

      progress_bar = nil
      # optionally track the in-memory evaluations, which is the expensive work
      if progress
        puts "Processing pool[#{@pool.id}] eligibility: #{@pool.requirement_expression.inspect}, priority: #{@pool.priority_expression.inspect}"
        progress_bar = ProgressBar.new(clients.count, :counter, :bar, :percentage, :rate, :eta)
      end

      processed_client_ids = []
      prefilter_result = @prefilter.call(clients)
      removed_client_snapshots = generate_snapshots(prefilter_result.removed_clients, progress_bar)

      # In incremental mode, track all input clients that should be processed so we can
      # remove candidates for clients that no longer pass filters (including SQL filter)
      processed_client_ids = clients.pluck(:id) if incremental

      started_at = Time.current
      prefilter_result.matching_clients.in_batches do |batch|
        now = Time.current
        # iterate through the batch to import any Client Proxies that aren't present in the db already
        proxies_by_client = @repo.import_proxies(batch, timestamp: now)

        # In full mode, track clients as we process them
        processed_client_ids += batch.map(&:id) unless incremental

        # Iterate through a second time to import candidate matches
        matching_candidates = []
        matching_client_snapshots = []
        batch.each do |client|
          progress_bar&.increment!
          evaluation = @evaluator.call(client)

          if evaluation.priority_score.nil?
            # Client without a score cannot be prioritized, so do not include them in the pool.
            # If needing to include clients that don't have a score, expression should be set up like `IF(my_score = NULL, 0, my_score)`
            removed_client_snapshots.push([client.id, evaluation.client_values])
            next
          end

          matching_candidates << {
            candidate_pool_id: @pool.id,
            client_proxy_id: proxies_by_client.fetch([client.id, client.class.name]).id,
            priority_score: evaluation.priority_score,
            created_at: now,
            updated_at: now,
          }
          matching_client_snapshots.push([client.id, evaluation.client_values])
        end

        @repo.import_candidates(matching_candidates)
        @event_writer.call(matching_client_snapshots, timestamp: now)
      end

      # Remove old candidates that no longer match
      if incremental
        # In incremental mode, only remove candidates for clients that were in the input scope
        # This ensures we remove candidates for clients who no longer pass any filters
        @repo.remove_stale_candidates(processed_client_ids: processed_client_ids, updated_before: started_at)
      else
        # In full mode, remove all candidates that were not updated during this run
        @repo.remove_all_stale_candidates(updated_before: started_at)
      end

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
end
