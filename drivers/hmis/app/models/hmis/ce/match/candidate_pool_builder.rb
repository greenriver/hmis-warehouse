# frozen_string_literal: true

# Manages the lifecycle of Candidate Pools, which are driven by rules associated with Unit Groups.
# This class ensures that pools are created for all unique rule sets, associates Unit Groups with
# the correct pools, and handles the initial assignment of Opportunities.
#
# The builder:
# 1. Creates Candidate Pools for all unique rule sets derived from Unit Groups.
# 2. Associates Unit Groups with their corresponding Candidate Pool.
# 3. Assigns new Opportunities to a pool and flags existing ones as "stale" if their rules change.
# 4. Cleans up orphaned pools that are no longer referenced by Unit Groups or Opportunities.
#
# Semantics and concurrency notes:
# - Do not move existing opportunities between pools on rule change; mark as `stale` instead.
# - A `nil` key represents the default case where no specific rules apply; do not create a pool for this key.
#   UnitGroups with a `nil` key will have `candidate_pool_id = NULL`.
# - Bulk creation relies on a DB unique index over (priority_expression, requirement_expression) and is idempotent.
# - Uses an advisory lock and a transaction to avoid concurrent races during batch operations.
#
module Hmis::Ce::Match
  class CandidatePoolBuilder
    def initialize(opportunities)
      @opportunities = opportunities
      @rule_resolver = Hmis::Ce::Match::UnitGroupRuleResolver.new
      @pool_repository = Hmis::Ce::Match::CandidatePoolRepository.new
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
      # Always process unit groups to keep waitlist (candidate pools) up to date regardless of opportunities
      unit_group_created_ids, unit_group_update_count = upsert_unit_group_pools!

      # Then process opportunities and their assignments without moving existing opportunities between pools
      grouped = opportunities_grouped_by_key(@opportunities)
      created_ids = @pool_repository.create_for_keys(grouped.keys)
      update_opportunity_pools!(grouped)
      cleanup_orphan_pools

      Rails.logger.info(
        format(
          '[CE CandidatePoolBuilder]: unit_groups_processed=%d, unit_group_associations_updated=%d, pools_created=%d',
          Hmis::UnitGroup.count,
          unit_group_update_count,
          (unit_group_created_ids.size + created_ids.size),
        ),
      )
      (unit_group_created_ids + created_ids).uniq
    end

    # Update the opportunity records with their candidate pools
    def update_opportunity_pools!(grouped)
      current_pools = @pool_repository.all_by_key

      # Collect all opportunity updates for a single upsert
      opportunity_updates = []

      grouped.each do |key, opportunities|
        target_pool = current_pools.fetch(key)

        opportunities.each do |opportunity|
          attrs = opportunity.attributes.symbolize_keys
          if opportunity.candidate_pool_id.nil?

            # New opportunity: assign to a pool and capture the rules at this moment for historical reporting.
            # The `assignment_rules` are NOT updated in subsequent runs to ensure stability for analytics,
            # even if the underlying rule definitions change. The `stale` flag indicates when the live
            # rules no longer match the initial assignment.
            opportunity_updates << attrs.merge(
              {
                candidate_pool_id: target_pool.id,
                stale: false,
                assignment_rules: @rule_resolver.rules_for_context(
                  unit_group: opportunity.unit&.unit_group,
                  project: opportunity.project,
                  organization: opportunity.project.organization,
                ).map(&:attributes),
              },
            )
          elsif opportunity.candidate_pool_id != target_pool.id
            # Existing opportunity - rules changed, flag as stale but don't change pool
            opportunity_updates << attrs.merge({ stale: true })
          elsif opportunity.stale?
            # Opportunity already in correct pool - ensure it's not flagged
            opportunity_updates << attrs.merge({ stale: false })
          end
        end
      end

      # Perform single bulk upsert if there are updates
      return unless opportunity_updates.any?

      result = Hmis::Ce::Opportunity.import!(
        opportunity_updates,
        on_duplicate_key_update: {
          conflict_target: [:id],
          columns: [:candidate_pool_id, :stale, :assignment_rules],
        },
      )
      raise "Failed to update CE Opportunities: #{result.inspect}" if result.failed_instances.present?
    end

    def now
      @now ||= Time.current
    end

    # Group opportunities by non-default keys; default (nil) keys are ignored
    # Returns a Hash: { [priority_expression, requirement_expression] => [opportunities...] }
    def opportunities_grouped_by_key(opportunity_scope)
      grouped = {}
      opportunity_scope.preload(:unit, project: [:organization, :funders]).find_each do |opportunity|
        unit_group = opportunity.unit&.unit_group
        key = @rule_resolver.key_for_unit_group(
          unit_group: unit_group,
          project: opportunity.project,
          organization: opportunity.project.organization,
        )
        next if key.nil?

        (grouped[key] ||= []) << opportunity
      end
      grouped
    end

    # Build and assign candidate pools for all unit groups.
    # - Compute effective key for each unit group
    # - Create pools for non-default keys
    # - Assign unit_groups.candidate_pool_id accordingly (NULL if default key)
    # Returns newly created pool IDs for dirty marking
    def upsert_unit_group_pools!
      keys_by_unit_group_id = @rule_resolver.keys_for_all_unit_groups

      # Create pools for unique keys
      created_ids = @pool_repository.create_for_keys(keys_by_unit_group_id.values.uniq.compact)

      # Prepare bulk updates for unit groups
      unit_group_updates = []
      pools_by_key = @pool_repository.all_by_key
      Hmis::UnitGroup.where(id: keys_by_unit_group_id.keys).find_each do |unit_group|
        computed_key = keys_by_unit_group_id[unit_group.id]
        candidate_pool_id = pools_by_key[computed_key]&.id if computed_key

        next if unit_group.candidate_pool_id == candidate_pool_id

        # Pass all attributes to satisfy validations
        unit_group_updates << unit_group.attributes.symbolize_keys.merge(candidate_pool_id: candidate_pool_id)
      end

      updated_count = 0
      if unit_group_updates.any?
        result = Hmis::UnitGroup.import!(
          unit_group_updates,
          on_duplicate_key_update: {
            conflict_target: [:id],
            columns: [:candidate_pool_id],
          },
        )
        raise "Failed to update Unit Groups with candidate pool assignments: #{result.inspect}" if result.failed_instances.present?

        updated_count = unit_group_updates.size
      end

      [created_ids, updated_count]
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
