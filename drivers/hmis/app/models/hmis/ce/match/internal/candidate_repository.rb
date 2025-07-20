# frozen_string_literal: true

module Hmis::Ce::Match::Internal
  # A repository pattern implementation responsible for all database operations
  # related to the `Candidate` and `ClientProxy` models. It handles creation,
  # updating (via conflict resolution), and deletion of records.
  class CandidateRepository
    def initialize(pool)
      @pool = pool
    end

    def import_proxies(clients, timestamp:)
      values = clients.map do |client|
        {
          client_id: client.id,
          client_type: client.class.sti_name,
          created_at: timestamp,
          updated_at: timestamp,
        }
      end

      result = Hmis::Ce::ClientProxy.import(values, on_duplicate_key_ignore: true)
      raise "failed to import ClientProxies: #{result.inspect}" if result.failed_instances.present?
    end

    # return a map of client_id to client_proxy_id
    def proxy_ids_by_warehouse_client(clients)
      Hmis::Ce::ClientProxy.warehouse_clients.
        where(client_id: clients.map(&:id)).
        pluck(:client_id, :id).to_h
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

    def remove_stale_candidates(client_ids:, updated_before:)
      client_proxy_ids = Hmis::Ce::ClientProxy.warehouse_clients.
        where(client_id: client_ids).
        pluck(:id)

      @pool.candidates.where(client_proxy_id: client_proxy_ids, updated_at: ...updated_before).delete_all
    end

    # the intersection of clients and the clients already in the candidate pool
    def current_warehouse_client_ids(clients)
      @pool.warehouse_clients.where(id: clients.select(:id)).pluck(:id).to_set
    end

    def remove_all_stale_candidates(updated_before:)
      @pool.candidates.where(updated_at: ...updated_before).delete_all
    end
  end
end
