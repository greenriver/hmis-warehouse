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
        Hmis::Ce::Match::CandidatePool.transaction do
          updated_ids = _perform
        end
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
      created_ids = create_new_pools!(grouped.keys)
      update_opportunity_pools!(grouped)
      cleanup_orphan_pools
      created_ids
    end

    # Update the opportunity records with their candidate pools
    def update_opportunity_pools!(grouped)
      current_pools = @candidate_pool_resolver.reload_candidate_pools_by_key

      # Collect all opportunity updates for a single upsert
      opportunity_updates = []

      grouped.each do |key, opportunities|
        target_pool = current_pools.fetch(key)

        opportunities.each do |opportunity|
          attrs = opportunity.attributes.symbolize_keys
          if opportunity.candidate_pool_id.nil?
            target_rule_attrs = @candidate_pool_resolver.opportunity_rules(opportunity).map(&:attributes)

            # New opportunity - assign to pool and capture the current rules for historical reporting
            opportunity_updates << attrs.merge(
              {
                candidate_pool_id: target_pool.id,
                stale: false,
                initial_rule_attrs: target_rule_attrs,
              },
            )
          elsif opportunity.candidate_pool_id != target_pool.id
            # Existing opportunity - rules changed, flag as stale but don't change pool
            opportunity_updates << attrs.merge(
              {
                candidate_pool_id: opportunity.candidate_pool_id, # Keep existing pool
                stale: true,
              },
            )
          elsif opportunity.stale?
            # Opportunity already in correct pool - ensure it's not flagged
            opportunity_updates << attrs.merge(
              {
                stale: false,
              },
            )
          end
        end
      end

      # Perform single bulk upsert if there are updates
      return unless opportunity_updates.any?

      result = Hmis::Ce::Opportunity.import!(
        opportunity_updates,
        on_duplicate_key_update: {
          conflict_target: [:id],
          columns: [:candidate_pool_id, :stale, :initial_rule_attrs],
        },
      )
      raise "Failed to update CE Opportunities: #{result.inspect}" if result.failed_instances.present?
    end

    def now
      @now ||= Time.current
    end

    # Create candidate pools, if they don't exist, for the given [priority, requirement] keys
    # Returns the IDs of newly created pools
    def create_new_pools!(values)
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

      result.ids
    end

    # Delete pools that haven't been used in a while
    def cleanup_orphan_pools
      duration = Hmis::Ce.configuration.days_to_retain_orphan_candidate_pools
      return unless duration

      expiration_date = now - duration.days
      Hmis::Ce::Match::CandidatePool.
        orphaned.
        where(updated_at: ...expiration_date).
        find_each(&:destroy!)
    end
  end
end
