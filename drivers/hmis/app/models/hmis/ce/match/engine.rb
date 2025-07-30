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
    def self.call(pool, clients: nil, progress: false, current_date: Date.current)
      new(pool, current_date: current_date).call(clients, progress: progress)
    end

    def initialize(pool, current_date: Date.current)
      @pool = pool
      @current_date = current_date
      @field_map = Hmis::Ce::Match::Expression::FieldMap.new(current_date: @current_date)
      @evaluator = Hmis::Ce::Match::Internal::ClientPoolEvaluator.new(@pool, @field_map, current_date: @current_date)
      @event_writer = Hmis::Ce::Match::Internal::CandidateEventWriter.new(@pool)
      @repo = Hmis::Ce::Match::Internal::CandidateRepository.new(@pool)
      @prefilter = Hmis::Ce::Match::Internal::SqlPrefilter.new(@pool, @field_map)
    end

    def call(clients, progress: false)
      # If clients are provided, incrementally process only provided clients and remove candidates only for those clients
      validate_clients_parameter!(clients) if clients

      # Full refresh - process all clients and remove all unmatched candidates
      clients = ::GrdaWarehouse::Hud::Client.destination if clients.nil?

      # optionally track the in-memory evaluations, which is the expensive work
      progress_bar = nil
      if progress
        progress_bar = new_progress_bar
        progress_bar.max += clients.count
      end

      started_at = Time.current
      # SQL Prefiltering
      prefilter_result = @prefilter.call(clients)

      # remove any current clients that the sql filter excluded
      if prefilter_result.lost_eligibility_clients.exists?
        Hmis::Ce::Match::Candidate.transaction do
          # capture snapshots at time of removal for the event log.
          # The intent to log the attributes that caused the client to lose eligibility
          snapshots = generate_snapshots(prefilter_result.lost_eligibility_clients, progress_bar)
          @repo.remove_warehouse_client_candidates(prefilter_result.lost_eligibility_clients)
          @event_writer.call(snapshots, timestamp: started_at)
        end
      end

      prefilter_result.eligible_clients.in_batches do |batch|
        now = Time.current
        # import missing Client Proxies
        @repo.import_proxies(batch, timestamp: now)
        # efficient lookup for client_id => proxy_id
        warehouse_proxy_map = @repo.proxy_by_warehouse_client(batch)
        # track which clients in this batch are currently matched to the pool
        current_warehouse_clients_ids = @repo.current_warehouse_client_ids(batch).to_set
        # accumulate snapshots for changes to candidates
        matching_client_snapshots = []
        removed_client_snapshots = []

        # Perform In-Memory Evaluation on each client
        matching_candidates = []
        batch.each do |client|
          progress_bar&.increment!
          evaluation = @evaluator.call(client)

          if evaluation.failed?
            # track removal if the client is currently in the pool
            if client.id.in?(current_warehouse_clients_ids)
              snapshot = Snapshot.new(
                client_id: client.id,
                values: evaluation.client_values,
                event_name: 'remove',
              )
              removed_client_snapshots.push(snapshot)
            end

            # early exit
            next
          end

          matching_candidates << {
            candidate_pool_id: @pool.id,
            client_proxy_id: warehouse_proxy_map[client.id].id,
            priority_score: evaluation.priority_score,
            created_at: now,
            updated_at: now,
          }
          snapshot = Snapshot.new(
            client_id: client.id,
            values: evaluation.client_values,
            event_name: client.id.in?(current_warehouse_clients_ids) ? 'update' : 'add',
          )
          matching_client_snapshots.push(snapshot)
        end

        Hmis::Ce::Match::Candidate.transaction do
          # import new candidates and log the events
          updated_candidate_ids = @repo.import_candidates(matching_candidates)
          candidate_map = @repo.candidates_by_warehouse_client(updated_candidate_ids)
          @event_writer.call(
            # filter out snapshots that didn't change
            matching_client_snapshots.filter { |s| candidate_map.key?(s.client_id) },
            timestamp: now,
          )

          # remove stale candidates and log the events
          @repo.remove_warehouse_client_candidates(removed_client_snapshots.map(&:client_id))
          @event_writer.call(removed_client_snapshots, timestamp: now)
        end
      end

      @pool.update!(candidates_generated_at: Time.current)
    end

    # helper for managing client values for event logging
    Snapshot = Struct.new(:client_id, :values, :event_name, keyword_init: true)
    # private_constant :Snapshot # keep public for tests

    private

    def validate_clients_parameter!(clients)
      raise ArgumentError, "clients must be an ActiveRecord relation, got #{clients.class.name}" unless clients.is_a?(ActiveRecord::Relation) && clients.klass == GrdaWarehouse::Hud::Client
    end

    def generate_snapshots(clients, progress_bar)
      snapshots = []

      progress_bar&.max += clients.count
      clients.find_each do |client|
        snapshot = Snapshot.new(
          client_id: client.id,
          values: @evaluator.call(client).client_values,
          event_name: 'remove',
        )
        snapshots.push(snapshot)
        progress_bar&.increment!
      end
      snapshots
    end

    def new_progress_bar
      puts "Processing pool[#{@pool.id}] eligibility: #{@pool.requirement_expression.inspect}, priority: #{@pool.priority_expression.inspect}"
      ProgressBar.new(0, :counter, :bar, :percentage, :rate, :eta)
    end
  end
end
