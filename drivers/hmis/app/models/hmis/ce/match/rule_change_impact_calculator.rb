# frozen_string_literal: true

module Hmis::Ce::Match
  # Previews the impact of creating or changing a CE Match rule, per affected unit group.
  #
  # Today this only reports how many current pool candidates would be *removed* if the rule's expression
  # were applied; NOT how many clients would be *added*. Counting removals only requires evaluating
  # clients already in the pool ("how many fail this expression?"). Reporting additions would require
  # finding clients outside the pool who would newly qualify ("who in the broader universe would be
  # added?"), which is substantially more expensive. Additional impact metrics (e.g. added candidates)
  # can be added to this class later if product needs them.
  #
  # Expects an unpersisted Hmis::Ce::Match::Rule, or a persisted rule carrying in-memory changes.
  # Callers should validate the rule's expression using `Hmis::Ce::Match::Expression::Validator`
  # before invoking this service, which does not handle validation.
  #
  # Priority schemes are not supported here, since adding a priority scheme cannot add or remove candidates.
  class RuleChangeImpactCalculator
    Result = Struct.new(:affected_unit_groups, keyword_init: true)
    UnitGroupImpact = Struct.new(:unit_group, :current_candidate_count, :removed_candidate_count, keyword_init: true)

    def self.for_rule(rule:)
      new(rule: rule).call
    end

    def initialize(rule:)
      @rule = rule
    end

    def call
      raise ArgumentError, 'priority scheme impact preview is not supported' if @rule.priority_scheme?

      Result.new(affected_unit_groups: unit_group_impacts)
    end

    private

    def unit_group_impacts
      Rule.unit_groups_for_owner(@rule.owner, applicability_config: @rule.applicability_config).
        filter_map { |unit_group| impact_for_unit_group(unit_group) }
    end

    def impact_for_unit_group(unit_group)
      # We don't calculate impact for unit groups that don't have a candidate pool yet.
      # Currently this RuleChangeImpactCalculator only measures *removals*, and if the unit group
      # doesn't have a candidate pool yet, it doesn't have any candidates to remove.
      pool_id = unit_group.candidate_pool_id
      return unless pool_id

      # Multiple unit groups frequently share the same candidate pool; memoize the
      # per-pool counts so we only load clients and evaluate the expression once per pool.
      counts = counts_for_pool(pool_id)

      UnitGroupImpact.new(
        unit_group: unit_group,
        current_candidate_count: counts[:current],
        removed_candidate_count: counts[:removed],
      )
    end

    def counts_for_pool(pool_id)
      @counts_by_pool_id ||= {}
      @counts_by_pool_id[pool_id] ||= begin
        clients = Hmis::Ce::Match::CandidatePool.find(pool_id).warehouse_clients.load # `.load` materializes the relation once for performance
        current_count = clients.size
        removed_count = current_count.zero? ? 0 : count_removed_candidates(clients, @rule.expression)
        { current: current_count, removed: removed_count }
      end
    end

    def count_removed_candidates(clients, expression)
      return 0 if clients.none?

      # Initialize an unpersisted pool (with a meaningless priority expression)
      # for evaluating clients against the new requirement.
      preview_pool = CandidatePool.new(requirement_expression: expression, priority_expression: '{1}')

      field_map = Expression::FieldMap.new
      evaluator = Internal::ClientPoolEvaluator.new(clients, preview_pool, field_map)

      clients.count { |client| evaluator.call(client).failed? }
    end
  end
end
