# frozen_string_literal: true

module Hmis::Ce::Match
  # Resolves rule-derived keys for UnitGroup contexts.
  # Returns nil when no specific rules apply.
  class UnitGroupRuleResolver
    # Compute the effective key for a UnitGroup.
    # Input: unit_group (required)
    # Output: [priority_expression, requirement_expression] or nil
    def key_for_unit_group(unit_group)
      rules = rules_for_unit_group(unit_group)

      priority_expression = compose_priority_expression(rules)
      requirement_expression = compose_requirement_expression(rules)

      # a valid pool needs both a priority and a requirement expression
      return unless priority_expression && requirement_expression

      [priority_expression, requirement_expression]
    end

    # Compute keys for all unit groups in the system.
    # Returns a Hash: { unit_group_id => [priority_expression, requirement_expression] }
    def keys_for_all_unit_groups(unit_group_scope = Hmis::UnitGroup.all)
      unit_group_scope.find_each.to_h do |unit_group|
        [
          unit_group.id,
          key_for_unit_group(unit_group),
        ]
      end.compact_blank
    end

    def rules_for_unit_group(unit_group)
      # In-memory filter of all rules is efficient due to small number of total rules.
      # The `by_owner_precedence` scope ensures deterministic key generation.
      all_rules.filter do |rule|
        rule.applies_to_entity?(unit_group)
      end
    end

    private

    def all_rules
      # Cache all Rules in an instance variable to reduce database hits
      # The set of rules is expected to be small enough to hold in memory for the life of the resolver.
      @all_rules ||= Hmis::Ce::Match::Rule.by_owner_precedence.preload(:owner).to_a
    end

    # Transform multiple priority scheme rules into a single expression that returns a Dentaku array {item1, item2, ...}
    def compose_priority_expression(rules)
      rules = rules.filter(&:priority_scheme?).sort_by { |r| [r.rank, r.id] }
      return if rules.empty?

      # Multiple ranked priority rules may apply to a unit group.
      # These priority rules must all share the same owner type because `rank` is only unique
      # with respect to owner; mixing owner types is ambiguous. Therefore if there are rules
      # with different owners, pick the filter the rules to only the most specific owner
      most_specific_level = rules.map(&:owner_precedence).min
      rules = rules.filter { |rule| rule.owner_precedence == most_specific_level }

      "{#{rules.map(&:expression).join(', ')}}"
    end

    def compose_requirement_expression(rules)
      # All applicable eligibility requirements are combined with AND.
      rules.filter(&:eligibility_requirement?).
        map(&:expression).
        join(' AND ').presence
    end
  end
end
