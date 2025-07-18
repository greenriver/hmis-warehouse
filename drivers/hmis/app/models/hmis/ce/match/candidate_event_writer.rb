# frozen_string_literal: true

module Hmis::Ce::Match
  # Responsible for writing candidate events (`add`, `update`, `remove`) to the
  # `ce_match_candidate_events` table. It determines the correct event type
  # based on the candidate's history and bulk-imports the events.
  class CandidateEventWriter
    def initialize(pool)
      @pool = pool
    end

    def call(snapshots, timestamp:)
      return if snapshots.empty?

      client_ids = snapshots.map(&:first)
      client_proxy_id_lookup = Hmis::Ce::ClientProxy.
        where(client_type: 'GrdaWarehouse::Hud::Client').
        where(client_id: client_ids).
        pluck(:client_id, :id).to_h

      event_lookup = @pool.candidates.
        where(client_proxy_id: client_proxy_id_lookup.values).
        pluck(:client_proxy_id, Arel.sql("CASE WHEN created_at = updated_at THEN 'add' ELSE 'update' END")).
        to_h

      values = snapshots.map do |client_id, snapshot|
        # This will raise if a client doesn't have a proxy, which is what we want.
        # It indicates a logic error elsewhere, as proxies should be created before events.
        client_proxy_id = client_proxy_id_lookup.fetch(client_id)
        event = event_lookup[client_proxy_id] || 'remove'
        {
          event_name: event,
          snapshot: snapshot,
          candidate_pool_id: @pool.id,
          client_proxy_id: client_proxy_id,
          created_at: timestamp,
        }
      end
      CandidateEvent.import!(values)
    end
  end
end
