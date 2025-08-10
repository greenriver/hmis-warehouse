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
# - Concurrency/transactions are handled by callers. This class performs pure operations without
#   acquiring locks or opening transactions.
#
module Hmis::Ce::Match
  class CandidatePoolBuilder

    def initialize
      @rule_resolver = Hmis::Ce::Match::UnitGroupRuleResolver.new
      @pool_repository = Hmis::Ce::Match::CandidatePoolRepository.new
    end

    # Class-level convenience
    def self.call(...) = new.call(...)

    def call(unit_group_ids: nil, force_reprocessing: false)
      unit_group_scope = Hmis::UnitGroup.all
      unit_group_scope = unit_group_scope.where(id: unit_group_ids) if unit_group_ids

      created_pool_ids, updated_unit_group_count = upsert_unit_group_pools!(unit_group_scope)

      if force_reprocessing
        Hmis::Ce::Match::CandidatePool.mark_all_dirty
      elsif created_pool_ids.any?
        Hmis::Ce::Match::CandidatePool.where(id: created_pool_ids).mark_all_dirty
      end

      update_stale_flags!
      cleanup_orphan_pools

      Rails.logger.info(
        format(
          '[CE CandidatePoolBuilder]: unit_groups_processed=%d, associations_updated=%d, pools_created=%d',
          unit_group_scope.count,
          updated_unit_group_count,
          created_pool_ids.size,
        ),
      )
    end

    private

    # Build and assign candidate pools for all unit groups.
    # - Compute effective key for each unit group
    # - Create pools for non-default keys
    # - Assign unit_groups.candidate_pool_id accordingly (NULL if default key)
    # Returns newly created pool IDs for dirty marking
    def upsert_unit_group_pools!(unit_group_scope)
      keys_by_unit_group_id = @rule_resolver.keys_for_all_unit_groups(unit_group_scope)

      # Create pools for unique keys
      created_ids = @pool_repository.create_for_keys(keys_by_unit_group_id.values.uniq.compact)

      # Prepare bulk updates for unit groups
      unit_group_updates = []
      pools_by_key = @pool_repository.all_by_key
      unit_group_scope.where(id: keys_by_unit_group_id.keys).find_each do |unit_group|
        computed_key = keys_by_unit_group_id[unit_group.id]
        candidate_pool_id = pools_by_key[computed_key]&.id

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

    def update_stale_flags!
      # Mark opportunities as stale if their pool no longer matches their unit group's pool
      Hmis::Ce::Opportunity.active.
        joins(unit: :unit_group).
        where.not(hmis_unit_groups: { candidate_pool_id: nil }).
        where('ce_opportunities.candidate_pool_id != hmis_unit_groups.candidate_pool_id').
        update_all(stale: true)

      # Un-mark opportunities that are currently stale but are now in the correct pool
      # (e.g., if rules were changed and then changed back)
      Hmis::Ce::Opportunity.active.
        where(stale: true).
        joins(unit: :unit_group).
        where('ce_opportunities.candidate_pool_id = hmis_unit_groups.candidate_pool_id').
        update_all(stale: false)
    end

    def now
      @now ||= Time.current
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
