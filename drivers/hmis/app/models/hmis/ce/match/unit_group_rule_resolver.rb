# frozen_string_literal: true

module Hmis::Ce::Match
  # Resolves rule-derived keys for UnitGroup/Project/Organization contexts with optimized caching.
  # Returns nil when no specific rules apply
  class UnitGroupRuleResolver
    def initialize
      @rules_cache = {}
      @key_cache = {}
      @all_rules_by_precedence = nil
    end

    # Compute the effective key for a UnitGroup context.
    # Inputs: unit_group (may be nil), project, organization
    # Output: [priority_expression, requirement_expression] or nil when default
    def key_for_unit_group(unit_group:, project:, organization:)
      cache_key = entity_cache_key(unit_group, project, organization)
      return @key_cache[cache_key] if @key_cache.key?(cache_key)

      rules = rules_for_context(unit_group: unit_group, project: project, organization: organization)

      priority_expression = select_priority_expression(rules)
      requirement_expression = compose_requirement_expression(rules)

      return @key_cache[cache_key] = nil if priority_expression.nil? && requirement_expression.nil?

      key = [
        priority_expression || '0',
        requirement_expression || 'TRUE',
      ]
      @key_cache[cache_key] = key
    end

    # Compute keys for all unit groups in the system
    # Returns a Hash: { unit_group_id => [priority_expression, requirement_expression] or nil }
    def keys_for_all_unit_groups
      results = {}
      Hmis::UnitGroup.preload(project: :organization).find_each do |unit_group|
        key = key_for_unit_group(
          unit_group: unit_group,
          project: unit_group.project,
          organization: unit_group.project.organization,
        )
        results[unit_group.id] = key
      end
      results
    end

    def rules_for_context(unit_group:, project:, organization:)
      cache_key = entity_cache_key(unit_group, project, organization)
      return @rules_cache[cache_key] if @rules_cache.key?(cache_key)

      entity = unit_group || project || organization
      return @rules_cache[cache_key] = [] unless entity

      applicable_rules = all_rules_by_precedence.filter { |rule| rule.applies_to_entity?(entity) }
      @rules_cache[cache_key] = applicable_rules
    end

    private

    def entity_cache_key(unit_group, project, organization)
      [unit_group&.id, project&.id, organization&.id]
    end

    # Load and sort all rules once using the model's scope, then reuse for all subsequent operations
    def all_rules_by_precedence
      @all_rules_by_precedence ||= begin
        # preload owner is required for `rule.applies_to_entity?`
        rules = Hmis::Ce::Match::Rule.preload(:owner).by_owner_precedence.to_a
        rules.freeze # Immutable after loading
      end
    end

    def select_priority_expression(rules)
      rules.detect(&:priority_scheme?)&.expression
    end

    def compose_requirement_expression(rules)
      rules.filter(&:eligibility_requirement?).
        map(&:expression).
        join(' AND ').presence
    end
  end
end
