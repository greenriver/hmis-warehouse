# frozen_string_literal: true

module Hmis::Ce::Match
  # PORO describing a UnitGroup's candidate pool assignment change,
  # plus functionality to generate candidate events for the change.
  class UnitGroupPoolChange
    attr_reader :unit_group, :old_pool, :new_pool

    def initialize(unit_group:, old_pool:, new_pool:)
      @unit_group = unit_group
      @old_pool = old_pool
      @new_pool = new_pool
    end

    # Generate candidate events when this unit group's pool assignment changes.
    # Only generates events for clients whose eligibility status actually changes.
    # (If the client was in both the old pool and the new pool, no events are generated.)
    # Creates and does not save events; expect the caller to bulk-save
    def generate_candidate_events(timestamp: Time.current)
      if old_pool.nil? && new_pool.present?
        # Unit group didn't have a pool before, now it has one. Generate "add" events for candidates in the new pool
        create_events_for_pool(new_pool, new_pool.candidates, 'add', timestamp)

      elsif old_pool.present? && new_pool.nil?
        # Unit group previously had a pool, now it does not. Generate "remove" events for candidates in the old pool
        create_events_for_pool(old_pool, old_pool.candidates, 'remove', timestamp)

      elsif old_pool.present? && new_pool.present?
        # Unit group is moving from one pool to another: only generate events for clients whose status changes
        old_client_proxy_ids = old_pool.candidates.pluck(:client_proxy_id).to_set
        new_client_proxy_ids = new_pool.candidates.pluck(:client_proxy_id).to_set
        events = []

        # Candidates in old pool but NOT in new pool: Generate "remove" events
        removed_client_proxy_ids = old_client_proxy_ids - new_client_proxy_ids
        if removed_client_proxy_ids.any?
          removed_candidates = old_pool.candidates.where(client_proxy_id: removed_client_proxy_ids)
          events.concat(create_events_for_pool(old_pool, removed_candidates, 'remove', timestamp))
        end

        # Candidates in new pool but NOT in old pool: Generate "add" events
        added_client_proxy_ids = new_client_proxy_ids - old_client_proxy_ids
        if added_client_proxy_ids.any?
          added_candidates = new_pool.candidates.where(client_proxy_id: added_client_proxy_ids)
          events.concat(create_events_for_pool(new_pool, added_candidates, 'add', timestamp))
        end

        events
      else
        # For candidates in both pools, do not generate events. Client remains eligible for the unit group
        []
      end
    end

    private

    # Create events for this unit group for a set of candidates in a pool.
    def create_events_for_pool(pool, candidates_scope, event_name, timestamp)
      candidates = candidates_scope.includes(:client_proxy).to_a
      return [] if candidates.empty?

      # Since this event is generated based on a *unit group* changing its pool,
      # not based on the client's attributes changing or the pool's requirements changing,
      # don't bother trying to recreate the snapshot of the client's attributes.
      # Instead, grab the snapshot from the most recent existing event for that client proxy.
      # There should be at least one, since the client was previously eligible for at least one pool (either the old or the new one).
      snapshot_by_client_proxy_id = Hmis::Ce::Match::CandidateEvent.
        joins(:client_proxy).
        where(client_proxy_id: candidates.map(&:client_proxy_id).uniq).
        select('DISTINCT ON (client_proxies.id) client_proxies.id, ce_match_candidate_events.snapshot').
        order('client_proxies.id, ce_match_candidate_events.created_at DESC').
        pluck('client_proxies.id', 'ce_match_candidate_events.snapshot').
        to_h

      candidates.map do |candidate|
        client_proxy_id = candidate.client_proxy_id
        snapshot = snapshot_by_client_proxy_id[client_proxy_id] || {}

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
