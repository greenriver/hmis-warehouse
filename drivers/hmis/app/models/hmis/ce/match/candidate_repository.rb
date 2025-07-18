# frozen_string_literal: true

module Hmis::Ce::Match
  # A repository pattern implementation responsible for all database operations
  # related to the `Candidate` and `ClientProxy` models. It handles creation,
  # updating (via conflict resolution), and deletion of records.
  class CandidateRepository
    def initialize(pool)
      @pool = pool
    end

    def import_proxies(clients, timestamp:)
      # Get the list of clients that need a proxy created
      client_identifiers = clients.map { |c| [c.id, c.class.name] }
      client_class_names = client_identifiers.map(&:second).uniq
      client_ids = client_identifiers.map(&:first)

      existing_proxies = client_proxy_scope.where(client_id: client_ids).to_a
      proxies_by_client = existing_proxies.index_by { |p| [p.client_id, p.client_type] }

      # Create any missing proxies
      missing_clients = client_identifiers.reject { |id, type| proxies_by_client.key?([id, type]) }
      if missing_clients.any?
        new_proxies = missing_clients.map do |id, type|
          { client_id: id, client_type: type, created_at: timestamp, updated_at: timestamp }
        end
        client_proxy_scope.import!(new_proxies)
      end

      # Return a lookup hash of all proxies (existing and new) for the given clients
      client_proxy_scope.
        where(client_id: client_ids).
        index_by { |p| [p.client_id, p.client_type] }
    end

    def import_candidates(values)
      return if values.empty?

      result = Hmis::Ce::Match::Candidate.import(
        values, on_duplicate_key_update: {
          conflict_target: [:candidate_pool_id, :client_proxy_id],
          columns: [:priority_score, :updated_at],
        }
      )
      raise "failed to import Candidates: #{result.inspect}" if result.failed_instances.present?
    end

    def remove_stale_candidates(processed_client_ids:, updated_before:)
      client_proxy_ids = client_proxy_scope.
        where(client_id: processed_client_ids).
        pluck(:id)

      @pool.candidates.where(client_proxy_id: client_proxy_ids, updated_at: ...updated_before).delete_all
    end

    def remove_all_stale_candidates(updated_before:)
      @pool.candidates.where(updated_at: ...updated_before).delete_all
    end

    def client_proxy_scope
      Hmis::Ce::ClientProxy.warehouse_clients
    end
  end
end
