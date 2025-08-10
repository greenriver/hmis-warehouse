# frozen_string_literal: true

module Hmis::Ce::Match
  # Resolves rule-derived keys for UnitGroup/Project/Organization contexts without any caching.
  # Returns nil when no specific rules apply
  class UnitGroupRuleResolver
    def initialize
      @rules_cache = {}
      @key_cache = {}
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

    # Return rules applicable to the context, ordered deterministically by owner precedence then id
    OWNER_PRECEDENCE = {
      'Hmis::UnitGroup' => 0,
      'Hmis::Hud::Project' => 1,
      'Hmis::Hud::Organization' => 2,
    }.freeze
    private_constant :OWNER_PRECEDENCE

    def rules_for_context(unit_group:, project:, organization:)
      cache_key = entity_cache_key(unit_group, project, organization)
      return @rules_cache[cache_key] if @rules_cache.key?(cache_key)

      entity = unit_group || project || organization
      return [] unless entity

      candidates = all_rules_for_resolver.select { |rule| rule.applies_to_entity?(entity) }

      ordered = candidates.sort_by do |rule|
        precedence = OWNER_PRECEDENCE.fetch(rule.owner_type, 99)
        [precedence, rule.id || 0]
      end
      @rules_cache[cache_key] = ordered
      ordered
    end

    private

    def entity_cache_key(unit_group, project, organization)
      [unit_group&.id, project&.id, organization&.id]
    end

    def all_rules_for_resolver
      @all_rules_for_resolver ||= Hmis::Ce::Match::Rule.preload(:owner).order(:owner_type, :id).to_a
    end

    def select_priority_expression(rules)
      rules.detect(&:priority_scheme?)&.expression
    end

    def compose_requirement_expression(rules)
      rules.select(&:eligibility_requirement?).
        map(&:expression).
        join(' AND ').presence
    end
  end
end
