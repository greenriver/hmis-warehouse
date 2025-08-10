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

      priority_expression = select_priority_expression(rules)
      requirement_expression = compose_requirement_expression(rules)

      return nil if priority_expression.nil? && requirement_expression.nil?

      [
        priority_expression || '0',
        requirement_expression || 'TRUE',
      ]
    end

    # Compute keys for all unit groups in the system.
    # Returns a Hash: { unit_group_id => [priority_expression, requirement_expression] or nil }
    def keys_for_all_unit_groups(unit_group_scope = Hmis::UnitGroup.all)
      # Preload all rules once to avoid N+1 queries inside the loop.
      # This is feasible because the total number of rules is expected to be small.
      all_rules = Hmis::Ce::Match::Rule.by_owner_precedence.preload(:owner).to_a

      results = {}
      unit_group_scope.find_each do |unit_group|
        rules = all_rules.filter { |rule| rule.applies_to_entity?(unit_group) }
        priority_expression = select_priority_expression(rules)
        requirement_expression = compose_requirement_expression(rules)

        next if priority_expression.nil? && requirement_expression.nil?

        results[unit_group.id] = [
          priority_expression || '0',
          requirement_expression || 'TRUE',
        ]
      end
      results
    end

    def rules_for_unit_group(unit_group)
      # In-memory filter of all rules is efficient due to small number of total rules.
      # The `by_owner_precedence` scope ensures deterministic key generation.
      Hmis::Ce::Match::Rule.by_owner_precedence.preload(:owner).filter do |rule|
        rule.applies_to_entity?(unit_group)
      end
    end

    private

    def select_priority_expression(rules)
      # The first priority scheme found is used, respecting owner precedence.
      rules.detect(&:priority_scheme?)&.expression
    end

    def compose_requirement_expression(rules)
      # All applicable eligibility requirements are combined with AND.
      rules.filter(&:eligibility_requirement?).
        map(&:expression).
        join(' AND ').presence
    end
  end
end
