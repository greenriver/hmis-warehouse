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
      return [] if clients.empty?

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

      result.ids
    end

    # return a map of client_id to client_proxy
    def proxy_by_warehouse_client(clients_or_ids)
      client_ids = clients_or_ids.select(:id) if clients_or_ids.is_a?(ActiveRecord::Relation)
      client_ids ||= clients_or_ids

      Hmis::Ce::ClientProxy.for_warehouse_clients.
        where(client_id: client_ids).
        index_by(&:client_id)
    end

    def candidates_by_warehouse_client(candidate_ids)
      Hmis::Ce::Match::Candidate.
        where(id: candidate_ids).
        joins(:client_proxy).
        merge(Hmis::Ce::ClientProxy.for_warehouse_clients).
        pluck('ce_client_proxies.client_id', :id).
        to_h
    end

    def import_candidates(values)
      return [] if values.empty?

      # The `on_duplicate_key_update` clause is configured to update a candidate only if their
      # `priority_score` has changed. This is an intentional performance optimization that
      # avoids unnecessary database writes. It also has the side effect of preventing
      # 'update' events from being logged when a client's underlying data changes but their
      # calculated score remains the same.
      result = Hmis::Ce::Match::Candidate.import(
        values, on_duplicate_key_update: {
          conflict_target: [:candidate_pool_id, :client_proxy_id],
          columns: [:priority_score],
          condition: 'excluded.priority_score != ce_match_candidates.priority_score',
        }
      )
      raise "failed to import Candidates: #{result.inspect}" if result.failed_instances.present?

      result.ids
    end

    def remove_warehouse_client_candidates(clients_or_ids)
      client_ids = clients_or_ids.select(:id) if clients_or_ids.is_a?(ActiveRecord::Relation)
      client_ids ||= clients_or_ids

      client_proxy_ids = Hmis::Ce::ClientProxy.for_warehouse_clients.
        where(client_id: client_ids).
        pluck(:id)
      candidates = @pool.candidates.where(client_proxy_id: client_proxy_ids)
      candidates.delete_all
    end

    # the intersection of clients and the those already in the candidate pool
    def current_warehouse_client_ids(clients)
      @pool.warehouse_clients.where(id: clients.select(:id)).pluck(:id)
    end
  end
end
