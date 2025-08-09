# frozen_string_literal: true

module Hmis::Ce::Match
  # Encapsulates persistence and lookup for CandidatePools with process-local caching.
  class CandidatePoolRepository
    # Return a Hash: { [priority_expression, requirement_expression] => CandidatePool }
    def all_by_key
      @all_by_key ||= load_candidate_pools_by_key
    end

    # Find a CandidatePool by its key (Array[String, String])
    def find_by_key(key)
      return nil if key.nil?

      all_by_key[key]
    end

    # Create pools for the given keys if missing. Returns IDs for newly created pools.
    # Idempotent via DB unique index on (priority_expression, requirement_expression).
    def create_for_keys(keys)
      values = keys.compact.uniq
      return [] if values.empty?

      attrs = values.map do |priority_expression, requirement_expression|
        {
          priority_expression: priority_expression,
          requirement_expression: requirement_expression,
        }
      end

      result = Hmis::Ce::Match::CandidatePool.import(
        attrs,
        on_duplicate_key_ignore: {
          conflict_target: [:priority_expression, :requirement_expression],
        },
      )
      raise "Failed: #{result.failed_instances}" if result.failed_instances.present?

      # Invalidate cache after creation so callers see new pools
      clear_cache
      result.ids
    end

    # Clear the in-process cache (useful for tests or explicit refreshes)
    def clear_cache
      @all_by_key = nil
    end

    private

    def load_candidate_pools_by_key
      Hmis::Ce::Match::CandidatePool.order(:id).to_a.index_by do |pool|
        [pool.priority_expression, pool.requirement_expression]
      end
    end
  end
end
