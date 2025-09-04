# frozen_string_literal: true

#
# Hmis::Ce::Match::CandidatePool
#
# A dynamic waitlist of client candidates who match a specific set of Coordinated
# Entry (CE) rules. Each pool is uniquely defined by a combination of a
# `priority_expression` and a `requirement_expression`.
#
# The pool serves as the central context for the `Hmis::Ce::Match::Engine`, which
# evaluates clients against the pool's expressions to populate the waitlist with
# `Hmis::Ce::Match::Candidate` records.
#
# Candidate Pools are not intended to be created or managed manually. They are
# generated and maintained automatically by the `CandidatePoolBuilder` service.
#
# 1.  **Creation**: The builder inspects all `Hmis::UnitGroup`s and their associated
#     `Hmis::Ce::Match::Rule`s. For each unique combination of rules, it creates
#     a corresponding Candidate Pool.
#
# 2.  **Association**: Once a pool is created, the builder associates the relevant
#     `UnitGroup`s with it via the `candidate_pool_id` foreign key.
#
# 3.  **Cleanup**: Pools that are no longer referenced by any `UnitGroup` or active
#     `Opportunity` are considered "orphaned" and are automatically deleted after a
#     configurable period.
#
module Hmis::Ce::Match
  class CandidatePool < GrdaWarehouseBase
    # Bulk-managed, does not log to paper_trail
    self.table_name = 'ce_match_candidate_pools'
    has_one :change_marker, as: :trackable, class_name: 'Hmis::Ce::ChangeMarker', dependent: :destroy
    has_many :candidates, class_name: 'Hmis::Ce::Match::Candidate', foreign_key: :candidate_pool_id, dependent: :destroy
    has_many :opportunities, class_name: 'Hmis::Ce::Opportunity', dependent: :restrict_with_exception
    has_many :unit_groups, class_name: 'Hmis::UnitGroup', foreign_key: :candidate_pool_id, dependent: :restrict_with_exception
    has_many :ce_match_candidate_events, class_name: 'Hmis::Ce::Match::CandidateEvent', foreign_key: :candidate_pool_id, dependent: :destroy

    attr_readonly :requirement_expression, :priority_expression

    # Clean up the link from soft-deleted associations before deleting the pool. This avoids
    # foreign key constraint violations
    before_destroy :nullify_deleted_associations

    scope :active, -> {
      # Pool is active if there are any active Opportunities that reference it
      active_ids_for_opportunities = ::Hmis::Ce::Opportunity.active.pluck(:candidate_pool_id).compact.uniq
      # Pool is active if there are any UnitGroups that reference it
      active_ids_for_unit_groups = Hmis::UnitGroup.pluck(:candidate_pool_id).compact.uniq

      where(id: active_ids_for_opportunities + active_ids_for_unit_groups)
    }

    # orphan pools can be safely deleted after a period if inactivity.
    # currently we consider a pool orphaned if it is not tied to any opportunities or unit groups.
    #
    # Note this could be expanded to allow deleting additional pools if needed, including:
    # 1) Pools that are exclusively tied to closed opportunities. (Would require modification to opportunities relation :restrict_with_exception).
    # 2) Pools that are tied to Unit Groups that are no longer configured to have waitlists enabled (see Hmis::Hud::Project.with_waitlist_ce_referrals_enabled)
    scope :orphaned, -> {
      referenced_ids = [
        ::Hmis::Ce::Opportunity,
        ::Hmis::UnitGroup,
      ].flat_map do |scope|
        scope.where.not(candidate_pool_id: nil).distinct.pluck(:candidate_pool_id)
      end

      where.not(id: referenced_ids)
    }

    def self.mark_all_dirty
      Hmis::Ce::ChangeMarker.upsert_or_bump_version(
        'Hmis::Ce::Match::CandidatePool',
        trackable_ids: pluck(:id),
      )
    end

    def active?
      ::Hmis::Ce::Opportunity.active.exists?(candidate_pool_id: id) || Hmis::UnitGroup.exists?(candidate_pool_id: id)
    end

    def warehouse_clients
      proxy_scope = Hmis::Ce::ClientProxy.
        joins(:ce_match_candidates).
        where(ce_match_candidates: { candidate_pool_id: id })
      GrdaWarehouse::Hud::Client.joins(:ce_client_proxy).merge(proxy_scope)
    end

    def relevant_form_definition_identifiers
      # Gather relevant expressions for determining priority/eligibility in this candidate pool.
      # These look like: 'current_age > 18' or 'cde.custom_assessment.fieldname = 1'
      expressions = [requirement_expression, priority_expression]

      calculator = Hmis::Ce::Match::Expression::CalculatorFactory.build

      cde_fields = expressions.map do |expression|
        # For each expression, get the list of fields it references. E.g. ['current_age', 'cde.custom_assessment.fieldname']
        fields = calculator.dependencies(expression)

        fields.map do |field|
          # Use the FieldMap to map each field to its type, and skip if it isn't CDE
          field_type, resolved_field = Hmis::Ce::Match::Expression::FieldMap.field_type_for(field)
          next unless field_type == Hmis::Ce::Match::Expression::FieldMap::CDE

          resolved_field
        end.uniq
      end.flatten.compact.uniq

      # Gather all the CDEDs referenced by all CDE fields and return their form definition identifiers
      cdeds = Hmis::Ce::Match::Expression::CdeFieldMap.new.cdeds_for(cde_fields)
      cdeds.pluck(:form_definition_identifier).uniq
    end

    # Acquire a transactional advisory lock for CE Candidate Pool processing.
    # The lock is held for the duration of a DB transaction.
    def self.lock_for_maintenance!(transaction: true, timeout_seconds: 10, &block)
      lock_name = 'candidate-pool-maintenance'
      GrdaWarehouseBase.with_advisory_lock!(
        lock_name,
        timeout_seconds: timeout_seconds,
        transaction: transaction,
        &block
      )
    end

    # Executes a block with an advisory lock on this specific pool.
    # The lock can be blocking (with a timeout) or non-blocking (timeout_seconds: 0).
    #
    def lock_for_processing(timeout_seconds:, &block)
      lock_name = "hmis-ce_pool-#{id}"
      ::GrdaWarehouseBase.with_advisory_lock(lock_name, timeout_seconds: timeout_seconds, &block)
    end

    protected

    def nullify_deleted_associations
      [
        Hmis::Ce::Opportunity,
        Hmis::UnitGroup,
      ].each do |model|
        model.only_deleted.where(candidate_pool_id: id).update_all(candidate_pool_id: nil)
      end
    end
  end
end
