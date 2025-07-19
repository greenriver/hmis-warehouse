# frozen_string_literal: true

module Hmis::Ce::Match::Internal
  # Responsible for writing candidate events (`add`, `update`, `remove`) to the
  # `ce_match_candidate_events` table. It determines the correct event type
  # based on the candidate's history and bulk-imports the events.
  #
  # This class uses an implicit method to determine the event type, which relies
  # on the `Hmis::Ce::Match::Engine` to orchestrate database state correctly.
  #
  # Event Determination Logic:
  # - 'add': A candidate record exists and `created_at` equals `updated_at`.
  #   This indicates a new record was just inserted by the Engine.
  # - 'update': A candidate record exists and `created_at` is different from
  #   `updated_at`. This indicates an existing record was updated.
  # - 'remove': No candidate record is found for the client. The Engine must
  #   delete the candidate record *before* calling this writer for clients
  #   that are no longer eligible.
  class CandidateEventWriter
    def initialize(pool)
      @pool = pool
    end

    def call(snapshots, timestamp:)
      return if snapshots.empty?

      client_ids = snapshots.map(&:first)
      client_proxy_id_lookup = Hmis::Ce::ClientProxy.
        warehouse_clients.
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
      result = Hmis::Ce::Match::CandidateEvent.import!(values)
      raise "failed to import Events: #{result.inspect}" if result.failed_instances.present?
    end
  end
end
