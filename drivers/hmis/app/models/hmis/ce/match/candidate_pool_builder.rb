# frozen_string_literal: true

# update candidate pools to reflect the current opportunities, requirements and priority configuration

module Hmis::Ce::Match
  class CandidatePoolBuilder
    def initialize(opportunities)
      @opportunities = opportunities
      @candidate_pool_resolver = Hmis::Ce::Match::CandidatePoolResolver.new
    end

    # Optimization TBD. Assumes a relatively small number of active opportunities (1,000 or less)
    def perform
      updated_ids = []
      with_lock do
        now = Time.current
        Hmis::Ce::Match::CandidatePool.transaction do
          _perform
        end
        updated_ids = Hmis::Ce::Match::CandidatePool.where(configuration_updated_at: now...).pluck(:id)
      end
      updated_ids
    end

    protected

    def with_lock(&block)
      lock_name = self.class.name.demodulize
      GrdaWarehouseBase.with_advisory_lock(lock_name, timeout_seconds: 30, &block)
    end

    def _perform
      grouped = @candidate_pool_resolver.opportunities_by_key(opportunity_scope: @opportunities)
      update_pools!(grouped.keys)
      update_opportunity_pools!(grouped)
      cleanup_orphan_pools
    end

    # Update the opportunity records with their candidate pools
    def update_opportunity_pools!(grouped)
      current_pools = @candidate_pool_resolver.reload_candidate_pools_by_key
      grouped.each do |key, opportunities|
        pool = current_pools.fetch(key)
        @opportunities.where(id: opportunities.map(&:id)).update_all(candidate_pool_id: pool.id)
      end
    end

    def now
      @now ||= Time.current
    end

    # Create candidate pools, if they don't exist, for the given [priority, requirement] keys
    def update_pools!(values)
      attrs = values.map do |priority_expression, requirement_expression|
        {
          priority_expression: priority_expression,
          requirement_expression: requirement_expression,
          configuration_updated_at: now,
        }
      end
      result = Hmis::Ce::Match::CandidatePool.import(
        attrs,
        on_duplicate_key_update: {
          conflict_target: [:priority_expression, :requirement_expression],
          columns: [], # Don't update anything for existing pools
        },
      )
      raise "Failed: #{result.failed_instances}" if result.failed_instances.present?
    end

    # Delete pools that haven't been used in a while
    def cleanup_orphan_pools
      duration = Hmis::Ce.configuration.days_to_retain_orphan_candidate_pools
      return unless duration

      expiration_date = now - duration.days
      Hmis::Ce::Match::CandidatePool.
        where(configuration_updated_at: ...expiration_date).
        find_each(&:destroy!)
    end
  end
end
