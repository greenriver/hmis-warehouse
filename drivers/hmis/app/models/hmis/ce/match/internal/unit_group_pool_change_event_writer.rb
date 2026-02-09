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
  #   - Candidates in both pools get an 'update' event because their snapshot of attributes relevant to unit group eligibility has changed.
  class UnitGroupPoolChangeEventWriter
    include Memery

    def call(pool_changes, timestamp: Time.current)
      return if pool_changes.empty?

      # Expect at most 100s of changes, but each change can generate 1000s of events,
      # so import them per-pool instead of saving them in memory and bulk-importing.
      pool_changes.each do |change|
        events = generate_events_for_change(change: change, timestamp: timestamp)
        next unless events.any?

        result = Hmis::Ce::Match::CandidateEvent.import!(events)
        raise "failed to import Events: #{result.inspect}" if result.failed_instances.present?
      end
    end

    private

    # Generate candidate events for a single pool change.
    def generate_events_for_change(change:, timestamp:)
      old_pool = change.old_pool
      new_pool = change.new_pool
      unit_group = change.unit_group

      if old_pool.nil? && new_pool.present?
        # Unit group didn't have a pool before, now it has one. Generate "add" events for all clients in the new pool
        create_events_for_client_proxies(
          event_name: 'add',
          client_proxies: client_proxies_for_pool(new_pool.id),
          unit_group: unit_group,
          pool: new_pool,
          timestamp: timestamp,
        )

      elsif old_pool.present? && new_pool.nil?
        # Unit group previously had a pool, now it does not. Generate "remove" events for all clients in the old pool
        create_events_for_client_proxies(
          event_name: 'remove',
          client_proxies: client_proxies_for_pool(old_pool.id),
          unit_group: unit_group,
          pool: old_pool,
          timestamp: timestamp,
        )

      elsif old_pool.present? && new_pool.present?
        # Unit group is moving from one pool to another
        old_client_proxies = client_proxies_for_pool(old_pool.id)
        new_client_proxies = client_proxies_for_pool(new_pool.id)

        events = []

        # Candidates in old pool but NOT in new pool: Generate "remove" events
        removed_client_proxies = old_client_proxies - new_client_proxies
        if removed_client_proxies.any?
          events.concat(
            create_events_for_client_proxies(
              event_name: 'remove',
              client_proxies: removed_client_proxies,
              unit_group: unit_group,
              pool: old_pool,
              timestamp: timestamp,
            ),
          )
        end

        # Candidates in new pool but NOT in old pool: Generate "add" events
        added_client_proxies = new_client_proxies - old_client_proxies
        if added_client_proxies.any?
          events.concat(
            create_events_for_client_proxies(
              event_name: 'add',
              client_proxies: added_client_proxies,
              unit_group: unit_group,
              pool: new_pool,
              timestamp: timestamp,
            ),
          )
        end

        # Candidates in both pools: Generate "update" events
        remaining_client_proxies = old_client_proxies & new_client_proxies
        if remaining_client_proxies.any?
          events.concat(
            create_events_for_client_proxies(
              event_name: 'update',
              client_proxies: remaining_client_proxies,
              unit_group: unit_group,
              pool: new_pool,
              timestamp: timestamp,
            ),
          )
        end

        events
      end
    end

    # Create the given event (add, remove, or update) for these client proxies in this unit group
    def create_events_for_client_proxies(event_name:, client_proxies:, unit_group:, pool:, timestamp:)
      return [] if client_proxies.nil? || client_proxies.empty?

      warehouse_clients = GrdaWarehouse::Hud::Client.
        joins(:ce_client_proxy).
        merge(Hmis::Ce::ClientProxy.for_warehouse_clients.where(id: client_proxies.pluck(:id)))

      snapshots_by_warehouse_client_id = Hmis::Ce::Match::Engine.new(pool).get_client_values(warehouse_clients)

      client_proxies.map do |client_proxy|
        snapshot = if client_proxy.client_type == 'GrdaWarehouse::Hud::Client'
          snapshots_by_warehouse_client_id[client_proxy.client_id]
        else
          {}
        end

        {
          event_name: event_name,
          snapshot: snapshot,
          unit_group_id: unit_group.id,
          candidate_pool_id: pool.id,
          client_proxy_id: client_proxy.id,
          created_at: timestamp,
        }
      end
    end

    memoize def client_proxies_for_pool(pool_id)
      Hmis::Ce::ClientProxy.
        joins(:ce_match_candidates).
        merge(Hmis::Ce::Match::Candidate.where(candidate_pool_id: pool_id))
    end
  end
end
