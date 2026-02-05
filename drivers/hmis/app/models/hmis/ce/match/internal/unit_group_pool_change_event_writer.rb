# frozen_string_literal: true

module Hmis::Ce::Match::Internal
  # Responsible for writing candidate events when unit group pool assignments change.
  # Accepts a list of PoolChange structs and bulk-creates events for all changes.
  #
  # Similar to CandidateEventWriter, this is a simple persistence layer that bulk-imports event data.
  # Events are created:
  # - When a unit group is newly assigned to a pool: All candidates in the pool get an 'add' event for the unit group
  # - When a unit group is removed from a pool: All candidates in the pool get a 'remove' event for the unit group
  # - When a unit group is moved from one pool to another:
  #   - Candidates who were in the old pool and not the new pool get a 'remove' event, since they are no longer eligible for the unit group
  #   - Candidates who were in the new pool and not the old pool get an 'add' event, since they are newly eligible for the unit group
  #   - Candidates in both do not get events generated. Their eligibility hasn't changed
  class UnitGroupPoolChangeEventWriter
    def call(pool_changes, timestamp: Time.current)
      return if pool_changes.empty?

      # Collect all affected pools and preload all candidates grouped by pool ID
      affected_pool_ids = pool_changes.flat_map { |change| [change.old_pool&.id, change.new_pool&.id] }.compact.uniq
      candidates_by_pool_id = Hmis::Ce::Match::Candidate.
        where(candidate_pool_id: affected_pool_ids).
        includes(:client_proxy).
        group_by(&:candidate_pool_id)

      # Collect all client proxy IDs across all pools
      all_client_proxy_ids = candidates_by_pool_id.values.flatten.map(&:client_proxy_id).uniq

      # Preload most recent snapshots for all client proxies, grouped by [pool_id, client_proxy_id].
      # (Since these events are generated based on unit group (not client) changes,
      # don't bother asking the engine to re-create the client attributes snapshot.
      # Instead, get snapshot from the previous event in the pool.)
      snapshot_cache = Hmis::Ce::Match::CandidateEvent.
        where(client_proxy_id: all_client_proxy_ids, candidate_pool_id: affected_pool_ids).
        select('DISTINCT ON (ce_match_candidate_events.candidate_pool_id, ce_match_candidate_events.client_proxy_id)
                ce_match_candidate_events.client_proxy_id,
                ce_match_candidate_events.candidate_pool_id,
                ce_match_candidate_events.snapshot').
        order('ce_match_candidate_events.candidate_pool_id,
               ce_match_candidate_events.client_proxy_id,
               ce_match_candidate_events.created_at DESC,
               ce_match_candidate_events.id DESC').
        to_a.
        group_by { |e| [e.candidate_pool_id, e.client_proxy_id] }.
        transform_values { |events| events.first.snapshot }

      # Generate events for all changes
      events = pool_changes.flat_map do |change|
        generate_events_for_change(
          change: change,
          timestamp: timestamp,
          candidates_cache: candidates_by_pool_id,
          snapshot_cache: snapshot_cache,
        )
      end

      # Bulk insert all events
      return unless events.any?

      result = Hmis::Ce::Match::CandidateEvent.import!(events)
      raise "failed to import Events: #{result.inspect}" if result.failed_instances.present?
    end

    private

    # Generate candidate events for a single pool change.
    def generate_events_for_change(change:, timestamp:, candidates_cache:, snapshot_cache:)
      old_pool = change.old_pool
      new_pool = change.new_pool
      unit_group = change.unit_group

      if old_pool.nil? && new_pool.present?
        # Unit group didn't have a pool before, now it has one. Generate "add" events for candidates in the new pool
        create_events_for_candidates(
          unit_group: unit_group,
          pool: new_pool,
          candidates: candidates_cache[new_pool.id],
          event_name: 'add',
          timestamp: timestamp,
          snapshot_cache: snapshot_cache,
        )

      elsif old_pool.present? && new_pool.nil?
        # Unit group previously had a pool, now it does not. Generate "remove" events for candidates in the old pool
        create_events_for_candidates(
          unit_group: unit_group,
          pool: old_pool,
          candidates: candidates_cache[old_pool.id],
          event_name: 'remove',
          timestamp: timestamp,
          snapshot_cache: snapshot_cache,
        )

      elsif old_pool.present? && new_pool.present?
        # Unit group is moving from one pool to another: only generate events for clients whose status changes
        old_candidates = candidates_cache[old_pool.id] || []
        new_candidates = candidates_cache[new_pool.id] || []

        old_client_proxy_ids = old_candidates.map(&:client_proxy_id).to_set
        new_client_proxy_ids = new_candidates.map(&:client_proxy_id).to_set

        events = []

        # Candidates in old pool but NOT in new pool: Generate "remove" events
        removed_client_proxy_ids = old_client_proxy_ids - new_client_proxy_ids
        if removed_client_proxy_ids.any?
          removed_candidates = old_candidates.select { |c| removed_client_proxy_ids.include?(c.client_proxy_id) }
          events.concat(
            create_events_for_candidates(
              unit_group: unit_group,
              pool: old_pool,
              candidates: removed_candidates,
              event_name: 'remove',
              timestamp: timestamp,
              snapshot_cache: snapshot_cache,
            ),
          )
        end

        # Candidates in new pool but NOT in old pool: Generate "add" events
        added_client_proxy_ids = new_client_proxy_ids - old_client_proxy_ids
        if added_client_proxy_ids.any?
          added_candidates = new_candidates.select { |c| added_client_proxy_ids.include?(c.client_proxy_id) }
          events.concat(
            create_events_for_candidates(
              unit_group: unit_group,
              pool: new_pool,
              candidates: added_candidates,
              event_name: 'add',
              timestamp: timestamp,
              snapshot_cache: snapshot_cache,
            ),
          )
        end

        events
      else
        # For candidates in both pools, do not generate events. Clients remain eligible for the unit group
        []
      end
    end

    # Create events for a unit group for a specific set of candidates
    def create_events_for_candidates(unit_group:, pool:, candidates:, event_name:, timestamp:, snapshot_cache:)
      return [] if candidates.nil? || candidates.empty?

      candidates.map do |candidate|
        client_proxy_id = candidate.client_proxy_id
        snapshot = snapshot_cache[[pool.id, client_proxy_id]] || {}

        {
          event_name: event_name,
          snapshot: snapshot,
          unit_group_id: unit_group.id,
          candidate_pool_id: pool.id,
          client_proxy_id: client_proxy_id,
          created_at: timestamp,
        }
      end
    end
  end
end
