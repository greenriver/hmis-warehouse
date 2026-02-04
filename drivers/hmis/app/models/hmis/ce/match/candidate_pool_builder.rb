# frozen_string_literal: true

# Manages the lifecycle of Candidate Pools, which are driven by rules associated with Unit Groups.
# This class ensures that pools are created for all unique rule sets, associates Unit Groups with
# the correct pools, and maintains data integrity across related records.
#
# The builder:
# 1. Creates Candidate Pools for all unique rule sets derived from Unit Groups.
# 2. Associates Unit Groups with their corresponding Candidate Pool.
# 3. Marks newly created or all pools as "dirty" to trigger reprocessing.
# 4. Backfills `candidate_pool_id` for any `Opportunity` records that are missing it.
# 5. Updates stale flags for Opportunities when their pool differs from their unit group's pool.
# 6. Generates candidate events when unit group pool assignments change.
#
# Semantics and concurrency notes:
# - Do not move existing opportunities between pools on rule change; mark as `stale` instead.
# - A `nil` key represents the default case where no specific rules apply; do not create a pool for this key.
#   UnitGroups with a `nil` key will have `candidate_pool_id = NULL`.
# - Bulk creation relies on a DB unique index over (priority_expressions, requirement_expression) and is idempotent.
# - Concurrency/transactions are handled by callers. This class performs pure operations without
#   acquiring locks or opening transactions.
# - Triggered automatically by Rule and UnitGroup callbacks. Can be called manually via `CeBuilder`
module Hmis::Ce::Match
  class CandidatePoolBuilder
    def initialize
      @rule_resolver = Hmis::Ce::Match::UnitGroupRuleResolver.new
      @pool_repository = Hmis::Ce::Match::CandidatePoolRepository.new
    end

    # Class-level convenience
    def self.call(...) = new.call(...)

    def call(unit_group_ids: nil, force_reprocessing: false)
      unit_group_scope = Hmis::UnitGroup.with_ce_waitlists_enabled
      unit_group_scope = unit_group_scope.where(id: unit_group_ids) if unit_group_ids

      created_pool_ids, updated_unit_group_count = upsert_unit_group_pools!(unit_group_scope)

      if force_reprocessing
        Hmis::Ce::Match::CandidatePool.mark_all_dirty
      elsif created_pool_ids.any?
        Hmis::Ce::Match::CandidatePool.where(id: created_pool_ids).mark_all_dirty
      end

      backfill_opportunities_without_pools!
      update_stale_flags!

      log_info(
        format(
          'unit_groups_processed=%d, associations_updated=%d, pools_created=%d',
          unit_group_scope.count,
          updated_unit_group_count,
          created_pool_ids.size,
        ),
      )

      # After creating and dirtying pools, enqueue the processing job
      Hmis::Ce::ProcessPoolsJob.perform_later(wait_time: 10.minutes) if Hmis::Ce::ChangeMarker.dirty.pools.exists?
    end

    private

    # Normally the pool will be set by the mutation when the opportunity is created.
    def backfill_opportunities_without_pools!
      scope = Hmis::Ce::Opportunity.
        where(candidate_pool_id: nil).
        joins(unit: :unit_group).
        where(arel.ug_t[:candidate_pool_id].not_eq(nil))
      scope.preload(unit: :unit_group).find_each do |opportunity|
        unit_group = opportunity.unit.unit_group
        log_info("backfilling pool #{unit_group.candidate_pool_id} for opportunity #{opportunity.id}")
        opportunity.update!(
          candidate_pool_id: unit_group.candidate_pool_id,
          assignment_rules: @rule_resolver.rules_for_unit_group(unit_group).map(&:attributes),
        )
      end
    end

    # Build and assign candidate pools for all unit groups.
    # - Compute effective key for each unit group
    # - Create pools for non-default keys
    # - Assign unit_groups.candidate_pool_id accordingly (NULL if default key)
    # - Generate events when pool assignments change
    # Returns newly created pool IDs for dirty marking
    def upsert_unit_group_pools!(unit_group_scope)
      keys_by_unit_group_id = @rule_resolver.keys_for_all_unit_groups(unit_group_scope)

      # Create pools for unique keys
      created_ids = @pool_repository.create_for_keys(keys_by_unit_group_id.values.uniq.compact)

      # Prepare bulk updates for unit groups and track pool changes
      unit_group_updates = []
      pool_changes = []
      pools_by_key = @pool_repository.all_by_key

      unit_group_scope.where(id: keys_by_unit_group_id.keys).includes(:candidate_pool).find_each do |unit_group|
        computed_key = keys_by_unit_group_id[unit_group.id]
        old_pool = unit_group.candidate_pool
        new_pool = pools_by_key[computed_key]

        next if old_pool&.id == new_pool&.id

        # Track pool changes for event generation
        pool_changes << Hmis::Ce::Match::UnitGroupPoolChange.new(unit_group: unit_group, old_pool: old_pool, new_pool: new_pool)

        # Pass all attributes to satisfy validations
        unit_group_updates << unit_group.attributes.symbolize_keys.merge(candidate_pool_id: new_pool&.id)
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

        # Generate events for each unit group whose candidate pool assignment changed
        timestamp = Time.current
        events = pool_changes.flat_map { |change| change.generate_candidate_events(timestamp: timestamp) }
        if events.any?
          result = Hmis::Ce::Match::CandidateEvent.import!(events)
          raise "failed to import Events: #{result.inspect}" if result.failed_instances.present?
        end
      end

      [created_ids, updated_count]
    end

    def update_stale_flags!
      op_scope = Hmis::Ce::Opportunity.where.not(candidate_pool_id: nil).joins(unit: :unit_group)

      # Mark opportunities as stale if their pool no longer matches their unit group's pool
      op_scope.
        where(arel.opp_t[:candidate_pool_id].not_eq(arel.ug_t[:candidate_pool_id])).
        update_all(stale: true)

      # Un-mark opportunities that are currently stale but are now in the correct pool
      # (e.g., if rules were changed and then changed back)
      op_scope.
        where(arel.opp_t[:candidate_pool_id].eq(arel.ug_t[:candidate_pool_id])).
        update_all(stale: false)
    end

    def now
      @now ||= Time.current
    end

    def arel
      Hmis::ArelHelper.instance
    end

    def log_info(message)
      Rails.logger.info { "[CandidatePoolBuilder] #{message}" }
    end
  end
end
