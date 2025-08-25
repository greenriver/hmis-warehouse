# frozen_string_literal: true

module Hmis::Ce::Match::Internal
  # Responsible for writing candidate events (`add`, `update`, `remove`) to the
  # `ce_match_candidate_events` table.
  #
  # This class is a simple persistence layer that bulk-imports event data.
  # The `Hmis::Ce::Match::Engine` is responsible for determining *when* an event
  # should be logged and what the event type (`event_name`) should be.
  # Events are only created for meaningful changes:
  # - `add`: A client becomes a candidate for a pool for the first time.
  # - `update`: A candidate's `priority_scores` change.
  # - `remove`: A client is no longer a candidate for a pool.
  class CandidateEventWriter
    def initialize(pool)
      @pool = pool
    end

    def call(snapshots, timestamp:)
      return if snapshots.empty?

      client_ids = snapshots.map(&:client_id)
      client_proxy_id_lookup = Hmis::Ce::ClientProxy.
        for_warehouse_clients.
        where(client_id: client_ids).
        pluck(:client_id, :id).to_h

      values = snapshots.map do |snapshot|
        # This will raise if a client doesn't have a proxy, which is what we want.
        # It indicates a logic error elsewhere, as proxies should be created before events.
        client_proxy_id = client_proxy_id_lookup.fetch(snapshot.client_id)
        {
          event_name: snapshot.event_name,
          snapshot: snapshot.values,
          candidate_pool_id: @pool.id,
          client_proxy_id: client_proxy_id,
          created_at: timestamp,
        }
      end
      result = Hmis::Ce::Match::CandidateEvent.import!(values)
      raise "failed to import Events: #{result.inspect}" if result.failed_instances.present?
    end
  end
end
