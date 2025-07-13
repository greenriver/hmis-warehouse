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
    # @param clients [ActiveRecord::Relation] The clients to evaluate for eligibility
    # @param progress [Boolean] Whether to display a progress bar during processing
    # @param incremental [Boolean] If true, only remove candidates for clients that were processed in this run.
    #   If false, remove all candidates that weren't updated (full refresh behavior).
    def call(pool, clients, progress: false, incremental:)
      validate_clients_parameter!(clients)

      eligibility_evaluator = ClientExpressionEvaluator.new(pool.requirement_expression, field_map)
      priority_evaluator = ClientExpressionEvaluator.new(pool.priority_expression, field_map)

      filtered_clients = crude_eligibility_filter(pool.requirement_expression, clients)
      bar = new_progress_bar(filtered_clients.count) if progress
      processed_client_ids = []

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
        batch.each do |client|
          bar&.increment!
          # note, we could also set an expiration date on the candidate to allow us to skip records we have evaluated recently
          next unless eligibility_evaluator.call(client)

          score = priority_evaluator.call(client)
          candidates << {
            candidate_pool_id: pool.id,
            client_proxy_id: proxies_by_client[[client.id, client.class.name]].id,
            priority_score: score,
            created_at: now,
            updated_at: now,
          }
        end
        import_candidates!(candidates)
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

      pool.update!(candidates_generated_at: Time.current)
    end

    protected

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
    end

    def crude_eligibility_filter(expression, clients)
      condition = SqlExpressionTranslator.call(expression, field_map)
      condition ? clients.where(condition) : clients
    end

    def field_map
      @field_map ||= FieldMap.new
    end

    def new_progress_bar(total)
      ProgressBar.new(total, :counter, :bar, :percentage, :rate, :eta)
    end
  end
end
