# frozen_string_literal: true

# Manages the lifecycle of Candidate Pools, which are driven by rules associated with Unit Groups.
# This class ensures that pools are created for all unique rule sets, associates Unit Groups with
# the correct pools, and maintains data integrity across related records.
#
# The builder:
# 1. Creates Candidate Pools for all unique rule sets derived from Unit Groups.
# 2. Associates Unit Groups with their corresponding Candidate Pool.
# 3. Maintains the historical record of which pool a unit group was assigned to at a given time.
# 4. Marks newly created or all pools as "dirty" to trigger reprocessing.
# 5. Backfills `candidate_pool_id` for any `Opportunity` records that are missing it.
# 6. Updates stale flags for Opportunities when their pool differs from their unit group's pool.

# Semantics and concurrency notes:
# - Do not move existing opportunities between pools on rule change; mark as `stale` instead.
# - A `nil` key represents the default case where no specific rules apply; do not create a pool for this key.
#   UnitGroups with a `nil` key will have `candidate_pool_id = NULL`.
# - Bulk creation relies on a DB unique index over (priority_expressions, requirement_expression) and is idempotent.
# - Concurrency/transactions are handled by callers. This class performs pure operations without
#   acquiring locks or opening transactions.
# - Triggered automatically, *synchronously*, by Rule and UnitGroup callbacks, so our aim is to keep this fast and lightweight.
# - Can be called manually via `CeBuilder`
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
    # - Record history of unit group/pool assignments
    # Returns newly created pool IDs for dirty marking
    def upsert_unit_group_pools!(unit_group_scope)
      keys_by_unit_group_id = @rule_resolver.keys_for_all_unit_groups(unit_group_scope)

      # Create pools for unique keys
      created_ids = @pool_repository.create_for_keys(keys_by_unit_group_id.values.uniq.compact)

      # Prepare bulk updates for unit groups
      unit_group_updates = []
      pool_changes = [] # Track changes: { unit_group_id:, old_pool_id:, new_pool_id: }
      pools_by_key = @pool_repository.all_by_key

      unit_group_scope.find_each do |unit_group|
        computed_key = keys_by_unit_group_id[unit_group.id]
        old_pool_id = unit_group.candidate_pool_id
        # If the key is nil, the unit group should not be asssociated with a pool. If it has an existing one, it should be removed
        new_pool_id = computed_key ? pools_by_key[computed_key]&.id : nil

        next if old_pool_id == new_pool_id

        # Track the pool change for historical record
        pool_changes << {
          unit_group_id: unit_group.id,
          old_pool_id: old_pool_id,
          new_pool_id: new_pool_id,
        }

        # Pass all attributes to satisfy validations
        unit_group_updates << unit_group.attributes.symbolize_keys.merge(candidate_pool_id: new_pool_id)
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

        record_pool_unit_group_assignments!(pool_changes)
      end

      [created_ids, updated_count]
    end

    # Record historical pool/unit group assignments by closing old assignments and creating new ones
    def record_pool_unit_group_assignments!(pool_changes)
      return if pool_changes.empty?

      timestamp = Time.current

      # Close old assignments by setting ended_at
      old_assignments_to_close = pool_changes.select { |change| change[:old_pool_id].present? }
      if old_assignments_to_close.any?
        unit_group_ids = old_assignments_to_close.map { |change| change[:unit_group_id] }
        CandidatePoolUnitGroupAssignment.
          # Each unit group has one active assignment at a time,
          # so this should be safe even though we aren't checking pool IDs here
          active.where(unit_group_id: unit_group_ids).
          update_all(ended_at: timestamp)
      end

      # Create new assignments for new pool associations
      new_assignments = pool_changes.select { |change| change[:new_pool_id].present? }.map do |change|
        {
          unit_group_id: change[:unit_group_id],
          candidate_pool_id: change[:new_pool_id],
          started_at: timestamp,
        }
      end

      CandidatePoolUnitGroupAssignment.import!(new_assignments) if new_assignments.any?
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
