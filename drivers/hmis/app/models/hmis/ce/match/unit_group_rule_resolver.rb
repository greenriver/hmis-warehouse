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
      priority_rules = Hmis::Ce::Match::Rule.most_specific_priority_schemes_from(rules)
      return if priority_rules.empty?

      "{#{priority_rules.map(&:expression).join(', ')}}"
    end

    def compose_requirement_expression(rules)
      rules.filter(&:eligibility_requirement?).
        map { |rule| parenthesize_if_needed(rule.expression) }.
        join(' AND ').presence
    end

    def parenthesize_if_needed(expression)
      trimmed_expression = expression.strip
      return expression if trimmed_expression.blank?

      ast = calculator.ast(trimmed_expression)
      return expression unless contains_boolean_or?(ast)
      return expression if expression_is_grouped?(trimmed_expression)

      "(#{expression})"
    end

    def calculator
      Hmis::Ce::Match::Expression::CalculatorFactory.build
    end

    def contains_boolean_or?(node)
      return false unless node
      return true if node.is_a?(Dentaku::AST::Or)

      child_nodes =
        if node.is_a?(Dentaku::AST::And)
          [node.left, node.right]
        elsif node.respond_to?(:children)
          Array(node.children)
        elsif node.respond_to?(:args)
          Array(node.args)
        else
          []
        end

      child_nodes.any? { |child| contains_boolean_or?(child) }
    end

    def expression_is_grouped?(expression)
      return false unless expression.start_with?('(') && expression.end_with?(')')

      # This method determines if an expression is fully enclosed by its outer parentheses,
      # distinguishing between `(a OR b)` and `(a) OR (b)`. It works by parsing the
      # content *inside* the outer parentheses.
      #
      # - For `(a OR b)`, the inner content `a OR b` is a valid expression, so parse succeeds.
      # - For `(a) OR (b)`, the inner content `a) OR (b` is syntactically invalid, so parse fails.
      #
      # A successful parse confirms the parentheses are grouping a single, complete expression.
      calculator.ast(expression[1..-2])
      true
    rescue Dentaku::ParseError, Dentaku::TokenizerError
      false
    end
  end
end
