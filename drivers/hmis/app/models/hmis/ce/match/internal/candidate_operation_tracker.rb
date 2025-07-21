# frozen_string_literal: true

module Hmis::Ce::Match::Internal
  # Helper for managing operation metadata for event logging
  Operation = Struct.new(:client_proxy_id, :operation, :priority_score, keyword_init: true)

  # Responsible for tracking and creating explicit operation metadata (add/update/remove/unchanged)
  # to support accurate event logging. Centralizes all logic related to determining what
  # operations occurred during candidate pool processing.
  class CandidateOperationTracker
    def initialize(pool)
      @pool = pool
    end

    # Determine what operation occurred for each input value by comparing with existing state
    def determine_operations(values, existing_lookup)
      values.map do |value|
        proxy_id = value[:client_proxy_id]
        new_score = value[:priority_score]

        if (existing = existing_lookup[proxy_id])
          operation = existing.priority_score != new_score ? 'update' : 'unchanged'
        else
          operation = 'add'
        end

        Operation.new(
          client_proxy_id: proxy_id,
          operation: operation,
          priority_score: new_score,
        )
      end
    end

    # Create remove operations for clients who are being removed from the candidate pool
    def create_remove_operations_for_clients(client_snapshots, warehouse_proxy_map)
      client_snapshots.map do |snapshot|
        proxy_id = warehouse_proxy_map[snapshot.client_id]&.id
        Operation.new(
          client_proxy_id: proxy_id,
          operation: 'remove',
          priority_score: nil,
        )
      end
    end

    # Create remove operations for clients who lost eligibility through prefiltering
    def create_remove_operations_for_lost_eligibility(client_snapshots)
      # Batch lookup of proxies for efficiency
      client_ids = client_snapshots.map(&:client_id)
      proxy_lookup = Hmis::Ce::ClientProxy.for_warehouse_clients.
        where(client_id: client_ids).
        index_by(&:client_id)

      client_snapshots.map do |snapshot|
        proxy = proxy_lookup[snapshot.client_id]
        Operation.new(
          client_proxy_id: proxy&.id,
          operation: 'remove',
          priority_score: nil,
        )
      end
    end

    # Query existing candidates to understand current state before import
    def get_existing_candidates_lookup(values)
      proxy_ids = values.map { |v| v[:client_proxy_id] }
      @pool.candidates.
        where(client_proxy_id: proxy_ids).
        index_by(&:client_proxy_id)
    end
  end
end
