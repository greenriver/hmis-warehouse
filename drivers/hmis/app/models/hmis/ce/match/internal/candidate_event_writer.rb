# frozen_string_literal: true

module Hmis::Ce::Match::Internal
  # Responsible for writing candidate events (`add`, `update`, `remove`) to the
  # `ce_match_candidate_events` table. It uses explicit operation information
  # from the CandidateRepository to determine the correct event type and
  # bulk-imports the events.
  #
  # This class uses explicit operation tracking provided by the Engine, which
  # compares the state before and after candidate import operations to determine
  # exactly what changed.
  #
  # Event Determination Logic:
  # - 'add': A new candidate record was created during the import operation.
  # - 'update': An existing candidate record was modified (e.g., priority score changed).
  # - 'remove': A candidate record was deleted (handled separately in the Engine).
  class CandidateEventWriter
    def initialize(pool)
      @pool = pool
    end

    def call(snapshots, timestamp:, operations:)
      return if snapshots.empty?

      client_ids = snapshots.map(&:client_id)
      client_proxy_id_lookup = Hmis::Ce::ClientProxy.
        for_warehouse_clients.
        where(client_id: client_ids).
        pluck(:client_id, :id).to_h

      # Create operation lookup for explicit event determination
      operation_lookup = operations.index_by(&:client_proxy_id)

      values = snapshots.map do |snapshot|
        # This will raise if a client doesn't have a proxy, which is what we want.
        # It indicates a logic error elsewhere, as proxies should be created before events.
        client_proxy_id = client_proxy_id_lookup.fetch(snapshot.client_id)

        # Use explicit operation from the import result
        event = operation_lookup.fetch(client_proxy_id).operation

        {
          event_name: event,
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
