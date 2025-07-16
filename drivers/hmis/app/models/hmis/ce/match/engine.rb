# frozen_string_literal: true

require 'progress_bar'

# * Find all clients that match the given pools's eligibility requirements.
# * Score each client based on that pools's prioritization formula.
# * Persist the results as MatchCandidate records to be consumed by opportunities.
#
# See drivers/hmis/app/models/hmis/ce/README_FOR_CHANGE_MARKER.md
module Hmis::Ce::Match
  class Engine
    def self.call(...)
      new.call(...)
    end

    # Take a two-step approach to evaluating eligibility to achieve better performance.
    # 1. Translate the eligibility requirements expression into a SQL condition and filter the clients. Uses field_map.arel_node to achieve this translation. Expression components that cannot be represented in SQL are treated as truthy. This reduces the number of client records that we need to evaluate in the more expensive second step.
    # 2. Evaluate the eligibility requirement expression against each matched client. We expect all expression variables to be defined.
    #
    # @param pool [Hmis::Ce::Match::CandidatePool] The candidate pool to populate with matching clients
    # @param clients [ActiveRecord::Relation, nil] The clients to evaluate for eligibility. If nil, processes all destination clients (full refresh).
    # @param progress [Boolean] Whether to display a progress bar during processing
    def call(pool, clients: nil, progress: false)
      # Determine processing mode based on whether clients were provided
      if clients.nil?
        # Full refresh - process all clients and remove all unmatched candidates
        clients = ::GrdaWarehouse::Hud::Client.destination
        existing_client_ids = destination_client_ids(pool)
        incremental = false
      else
        # Incremental - process only provided clients and remove candidates only for those clients
        incremental = true
        validate_clients_parameter!(clients)
      end

      evaluator = ClientPoolEvaluator.new(pool, field_map)

      if progress
        puts "Processing pool[#{pool.id}] eligibility: #{pool.requirement_expression.inspect}, priority: #{pool.priority_expression.inspect}"
        progress_bar = ProgressBar.new(total, :counter, :bar, :percentage, :rate, :eta)
      end

      processed_client_ids = []
      [filtered_clients, removed_client_snapshots] = crude_eligibility_filter(pool, evaluator, clients)

      # In incremental mode, track all input clients that should be processed so we can
      # remove candidates for clients that no longer pass filters (including SQL filter)
      processed_client_ids = clients.pluck(:id) if incremental

      now = DateTime.current
      filtered_clients.in_batches do |batch|
        # First iterate through the batch to import any Client Proxies that aren't present in the db already
        proxies = []
        batch.each do |client|
          # In full mode, track clients as we process them
          processed_client_ids.push(client.id) unless incremental
          proxies << Hmis::Ce::ClientProxy.new(client: client)
        end
        proxies_by_client = import_proxies!(proxies)

        # Iterate through a second time to import candidate matches
        candidates = []
        matching_client_snapshots = []
        batch.each do |client|
          progress_bar&.increment!
          evaluation = evaluator.call(client)

          if evaluation.priority_score.nil?
            # Client without a score cannot be prioritized, so do not include them in the pool.
            # If needing to include clients that don't have a score, expression should be set up like `IF(my_score = NULL, 0, my_score)`
            removed_client_snapshots.push([client.id, evaluation.client_values])
            next
          end

          candidates << {
            candidate_pool_id: pool.id,
            client_proxy_id: proxies_by_client[[client.id, client.class.name]].id,
            priority_score: evaluation.priority_score,
            created_at: now,
            updated_at: now,
          }
          matching_client_snapshots.push([client.id, evaluation.client_values])
        end
        imported_candidate_ids = import_candidates!(candidates)
        # filter matching_client_snapshots to just imported

        write_events(added_client_snapshots, pool, 'add')
        write_events(updated_client_snapshots, pool, 'update')
      end

      # Remove old candidates that no longer match
      if incremental
        # In incremental mode, only remove candidates for clients that were in the input scope
        # This ensures we remove candidates for clients who no longer pass any filters
        pool.candidates.joins(:client_proxy).where(
          ce_client_proxies: { client_id: processed_client_ids, client_type: 'GrdaWarehouse::Hud::Client' },
        ).where(updated_at: ...now).delete_all
      else
        # In full mode, remove all candidates that weren't updated in this run
        pool.candidates.where(updated_at: ...now).delete_all
      end

      write_events(removed_client_snapshots, pool, 'remove')
      pool.update!(candidates_generated_at: Time.current)
    end

    protected

    def write_events(snapshots, pool, event_name)
      proxy_id_lookup = Hmis::Ce::ClientProxy
        .where(client_type: 'GrdaWarehouse::Hud::Client')
        .where(client_id: snapshots.map(&:first))
        .pluck(:client_id, :id).to_h

      values = snapshots.map do |client_id, snapshot|
        {
          event: event_name,
          snapshot: snapshot,
          candidate_pool_id: pool.id
          proxy_id: proxy_id_lookup.fetch(client_id)
        }
      end
      CandidateEvent.import!(values)
    end

    def validate_clients_parameter!(clients)
      raise ArgumentError, "clients must be an ActiveRecord relation, got #{clients.class.name}" unless clients.is_a?(ActiveRecord::Relation) && clients.klass == GrdaWarehouse::Hud::Client
    end

    def import_proxies!(values)
      result = Hmis::Ce::ClientProxy.import(values, on_duplicate_key_ignore: true)
      raise "failed to import ClientProxies: #{result.inspect}" if result.failed_instances.present?

      # return a map of [client_id, client_type] to ClientProxy
      # re-query the Hmis::Ce::ClientProxy table by client ID, not result ID, since duplicate clients would not be included in result.ids
      Hmis::Ce::ClientProxy.where(client: values.map(&:client)).each_with_object({}) do |record, hash|
        key = [record.client_id, record.client_type] # Composite key because client is polymorphic
        hash[key] = record
      end
    end

    def import_candidates!(values)
      result = Candidate.import(
        values, on_duplicate_key_update: {
          conflict_target: [:candidate_pool_id, :client_proxy_id],
          columns: [:priority_score, :updated_at],
        }
      )
      raise "failed to import Candidates: #{result.inspect}" if result.failed_instances.present?
      result.ids
    end

    # note, the filter only works on candidates that are destination clients
    def crude_eligibility_filter(pool, evaluator, client_universe, progress_bar)
      condition = SqlExpressionTranslator.call(pool.requirement_expression, field_map)
      return client_universe unless condition

      # we perform sql-filtering and then capture the attributes of those clients that no longer match (for event log)
      removed_client_snapshots = []
      # filter the universe
      matching_clients = client_universe.where(condition)
      # find all clients in the pool
      current_clients = pool.warehouse_clients.where(id: client_universe)
      # find all clients that no longer match the pool
      removed_clients = current_clients.where.not(id: matching_clients.select(:id))

      removed_count = removed_clients.count
      if removed_count > 0
        progress_bar.max += removed_count if progress_bar

        # capture the attributes for removed clients
        removed_clients.find_each do |client|
          snapshot = evaluator.call(client).client_values
          removed_client_snapshots.push([client.id, snapshot])
          progress_bar.increment!
        end
      end

      [
        matching_clients,
        removed_client_snapshots,
      ]
    end

    def field_map
      @field_map ||= FieldMap.new
    end
  end
end
